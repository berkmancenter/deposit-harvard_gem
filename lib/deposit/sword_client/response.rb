# SWORD Client Utilities
#  
# These utilities help to parse information
# out of responses received from a SWORD Server

require 'rexml/document'
# Must require ActiveRecord, as it adds the Hash.from_xml() method (used below)
require 'active_record'

class Deposit::SwordClient::Response

  # Parse the given SWORD Service Document.
  #
  # Returns a SwordClient::ParsedServiceDoc containing all the
  # information we could parse from the SWORD Service Document.
  def self.parse_service_doc_new(service_doc_response)

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

#..    @parsed_service_doc.collections << @curr_collection

    #If we aren't in a collection, and we encounter an <atom:title>,
    # then we've found the repository's name

      #capture the repository's name
#..      @parsed_service_doc.repository_name = value


#..       > root.each_element("workspace/atom:title") {|t| t.each {|e| p e}}
#..      "SWORD Test Group"
#..      "Default"

    #return SwordClient::ParsedServiceDoc
    docHandler.parsed_service_doc
  end

  # Parse the given SWORD Service Document.
  #
  # Returns a SwordClient::ParsedServiceDoc containing all the
  # information we could parse from the SWORD Service Document.
  def self.parse_service_doc(service_doc_response)
    
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