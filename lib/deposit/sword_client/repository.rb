# SWORD Client Repository

require 'rexml/document'
# Must require ActiveRecord, as it adds the Hash.from_xml() method (used below)
require 'active_record'

class Deposit::SwordClient::Repository

  # getsets for repo info
  attr_accessor :collections, :connection, :name, :parsed_service_document, :service_document

  def initialize(connection)
    # make the variables available
    @connection = connection

    # Load the service doc
    @service_document ||= @connection.service_document

    @coll2 = []
    @coll3 = []

    if false   # the old way
      # parse the service document
      @parsed_service_document = self.class.parse_service_doc_old(service_document)

      # set repo name
      @name = @parsed_service_document.repository_name

      # set the collections in the repo
      @collections = @parsed_service_document.collections
    else
      # The new, shiny way
      @parsed_service_document = parse_service_doc
      @parsed_service_document.collections = @coll2  # old stuff - TODO : remove this after new way is all sussed out
      @collections = @coll3
    end

  end

  def coll2
    @coll2
  end

  def coll3
    @coll3
  end

  def default_collection(params = {})
    # Find a default collection, based on params if we can, or just use the first one if we can't.
    default_collection = @collections.first

    @collections.each do |c|
      if params['default_collection_url']
        default_collection = c if c['deposit_url'].to_s.strip == params['default_collection_url'].strip
        break if default_collection # first matching collection wins!
      elsif params['default_collection_name']
        default_collection = c if c['title'].to_s.strip.downcase == params['default_collection_name'].strip.downcase
        break if default_collection # first matching collection wins!
      end
    end

    default_collection
  end

  # Parse the given SWORD Service Document.
  #
  # Returns a SwordClient::ParsedServiceDoc containing all the
  # information we could parse from the SWORD Service Document.
  def parse_service_doc(service_doc_response = @service_document)

    doc = REXML::Document.new service_doc_response
    root = doc.root

    parsed_service_doc = SwordClient::ParsedServiceDoc.new

    root.elements.each do |e|
      case e.expanded_name
      when "sword:version"
        parsed_service_doc.version = e.text
      when "sword:verbose"
        parsed_service_doc.verbose = e.text
      when "sword:noOp"
        parsed_service_doc.no_op = e.text
      when "sword:maxUploadSize"
        parsed_service_doc.max_upload_size = e.text
      end
    end

#.. root.each_element("//collection/") {|coll| puts "v"*80; puts "#{coll.expanded_name}: #{coll.elements['atom:title'].get_text}"; puts "v"*80; coll.each_element {|e| p e} ; puts "*"*80}
    root.each_element("//collection|//app:collection") do |collection|
      @coll3 << SwordClient::Collection.new(self, collection)

      current_collection = {'deposit_url' => collection.attributes['href']}

      collection.elements.each do |e|
        if e.name == "acceptPackaging"
          accept_packaging_rank = e.attributes["q"] ? e.attributes["q"].to_f : 1.0
          stack_and_save current_collection, e.name, {'rank' => accept_packaging_rank, 'value' => e.text}
      else
          current_collection[e.name] = e.text
        end
      end
      @coll2 << current_collection
    end

    # Mimic (for now) the current behavior in the stream parser, and
    # set the repo's name to the last non-collection atom:title node's value
    @name ||= root.elements["/*/*/atom:title[last()]"].get_text

    # Could also do it this way:

    #..       > root.each_element("workspace/atom:title") {|e| p e.text}
    #..      "SWORD Test Group"
    #..      "Default"

    parsed_service_doc
  end

  def deposit(collection = default_collection, filepath = nil, metadata = {}, headers = {})
    # create a deposit object
    object = Deposit::SwordClient::DepositObject.new("post", "collection", collection.deposit_url, filepath, metadata, headers, self)
    puts "*"*60
    puts "Object headers in #deposit are ", object.headers.inspect
    puts "*"*60
    response = @connection.post(object.object, object.target, object.headers)
  end

  # Saves a property value for the current collection.
  # This method ensures that multiple values are changed into an
  # array of values
  def stack_and_save destination, key, new_value
      #If this property already had a previous value(s) for this collection,
      # then we want to change this property into an array of all its values
      if destination[key]
        # If not already an Array, change into an Array
        if ! destination[key].kind_of? Array
          # Change property into an array of values
          destination[key] = [ destination[key] ]
        end

        # append to current array of values
        destination[key] << new_value
      else
        destination[key] = new_value
      end
  end

  # Parse the given SWORD Service Document.
  #
  # Returns a SwordClient::ParsedServiceDoc containing all the
  # information we could parse from the SWORD Service Document.
  def self.parse_service_doc_old(service_doc_response)
    
    # We will use SAX Parsing with REXML
    src = REXML::Source.new service_doc_response
    
    docHandler = SwordClient::ServiceDocHandler.new
    
    #parse Source Doc XML using our custom handler
    REXML::Document.parse_stream src, docHandler
    
    #return SwordClient::ParsedServiceDoc
    docHandler.parsed_service_doc
  end

  # Parses the response from post_file() call into 
  # a Hash similar which has the same general structure
  # as the ATOM XML.  Hash structure is similar to:
  #
  #   {'title' => <Deposited Item Title>,
  #    'id' => <Assigned ID to deposited item>,
  #    'content'  => {'src' => <URL of deposited item>}
  #    'link' => <Array of URLs of uploaded files within item>,
  #    'rights' => <URL of license assigned>,
  #    'server' => {'name' => <SWORD service Name>, 'uri'=> <URI> },
  #    'updated' => <Date deposited item was updated/deposited> }
  #
  def self.post_response_to_hash(response)

    #directly convert ATOM reponse to a Ruby Hash (uses REXML by default)
    response_hash = Hash.from_xml(response)

    #Remove any keys which represent XML namespace declarations ("xmlns:*")
    # (These are not recognized properly by Hash.from_xml() above)
    response_hash['entry'].delete_if{|key, value| key.to_s.include?("xmlns:")}

    # Return hash under the top 'entry' node
    response_hash['entry']
  end

end