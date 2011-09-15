# parse a SWORD collection document

require 'rexml/document'

class Deposit::SwordClient::Collection
  # TODO : I think I'm going to make the Big Dogs (deposit_url, title, accept_packagin)
  # just methods to pluck those elements from the @properties hash.
  attr_accessor :source, :collection, :deposit_url, :accept_packaging, :properties, :title

  # given a collection url, read it and get the edit links to the items in the collection
  def initialize(source)

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

  # return a list of the URLs to the items in this collection
  def items(collection = @collection)

    links = Array.new

    collection.entries.each { |entry| links << entry.edit_link.to_s }

    links
  end

end
