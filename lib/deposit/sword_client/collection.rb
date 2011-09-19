# parse a SWORD collection document

require 'rexml/document'

class Deposit::SwordClient::Collection
  # TODO : I think I'm going to make the Big Dogs (deposit_url, title, accept_packagin)
  # just methods to pluck those elements from the @properties hash.
  attr_accessor :source, :collection, :deposit_url, :accept_packaging, :properties, :title

  # Collection belongs to a repository.  Given a source, read it and get info about the
  # collection.
  def initialize(repository, source)
    # need this internally to have access to @repository.connection for pulling data
    @repository = repository

    @collection = @deposit_url = nil
    @properties = {}
    @accept_packaging = []

    @source = source

    if source.is_a? REXML::Element   # we're most often constructed while parsing service docs
      @deposit_url = source.attributes['href']

      source.elements.each do |e|
        case e.name
        when "acceptPackaging"
          accept_packaging_rank = e.attributes["q"] ? e.attributes["q"].to_f : 1.0
          @accept_packaging << {'rank' => accept_packaging_rank, 'value' => e.text}
        when "title"
          @title = e.text
        else
          @properties[e.name] = e.text
        end
      end
    end

#    raise SwordException, "source provided could not be parsed as ATOM" if @collection.nil?
  end

  def [](key)
    @properties[key]
  end

  def list
    unless @list
      response = @repository.connection.get @deposit_url
      @list = response.body
    end
    @list
  end

  def items
    @items ||= parse_list
  end

  # return a list of the URLs to the items in this collection
  def parse_list
    doc = REXML::Document.new(list)
    root = doc.root
    list_items = []
    root.elements.each("//atom:feed") do |entry|
      item = {}
      entry.elements.each do |e|
        case e.name
        when "id", "link", "updated"
          item[e.name] = e.text
        when "author"
          item[e.name] ||= []
          e.elements.each("atom:name") do |author|
            item[e.name] << author.text
          end
        end
      end
      list_items << item unless item.empty?
    end
    list_items
  end

end
