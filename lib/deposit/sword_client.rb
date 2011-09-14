# A Ruby-based SWORD Client
#
# This allows you to make requests (via HTTP) to an existing
# SWORD Server, including posting a file to a SWORD server.
#
# For more information on SWORD and the SWORD APP Profile:
#  http://www.swordapp.org/
#
# Gem extracted from the original 1.3 client in BibApp, which
# was possibly written by Tim Donohue. See: http://bibapp.org/
#
# Some connection code and classes originally from the Ruby
# Sword 2.0 client by Mark MacGillivray mark@cottagelabs.com,
# developed as part of the JISC SWORD 2.0 project.
# See http://cottagelabs.com/some-post-about-sword2_client-ruby-client
# for more info about that Ruby client gem.

# by Mark MacGillivray mark@cottagelabs.com

# == Configuration
#
# Configuration is done via <tt>RAILS_ROOT/config/sword.yml</tt> 
# and is loaded according to the <tt>RAILS_ENV</tt>.
# The minimum connection options that you must specify depend
# on the location of your SWORD server (and whether it requires
# authentication).  Minimally, you likely need to change
# "SWORD Service Document URL" and "SWORD Server Default Login"
#
# Example production configuration (RAILS_ROOT/config/sword.yml)
# 
# production:
#   # SWORD Server's Service Document URL
#   service_doc_url: http://localhost:8080/sword-app/servicedocument
#  
#   # SWORD Server Default Login credentials
#   username:
#   password:
#  
#   # Proxy Settings
#   #   Only necessary if you require a Proxy 
#   #   to connect to SWORD Server.  If using
#   #   a proxy, only the proxy_server is required.
#   proxy_server: my.proxy.edu
#   proxy_port: 80
#   proxy_username: myproxyuser
#   proxy_password: myproxypass
#  
#   # Default Collection to deposit to
#   #   URL should correspond to the Deposit URL
#   #   of a collection as returned by Service Document.
#   #   If unspecified, then a user will need to
#   #   select a collection *before* a deposit
#   #   can be made via SWORD
#   #
#   #   Either specify the Name of the Collection
#   #   OR specify the URL (but not BOTH!)
#   default_collection_url: http://localhost:8080/sword-app/deposit/123456789/4
#   #default_collection_name: My Collection

# Define a custom exception for Sword Client
class Deposit::SwordException < Exception; end

include Deposit

class Deposit::SwordClient
  
  # Currently initialized SWORD Connection
  attr_accessor :connection
  
  # Currently loaded SWORD configurations
  attr_accessor :config
  
  # Currently loaded SWORD service document
  attr_writer :service_doc
    
  # Currently parsed SWORD service document
  attr_writer :parsed_service_doc
  
  class << self
    def logger
      @@logger ||= ::Rails.logger if defined?(Rails.logger)
      @@logger ||= ::STDOUT
    end
  end
    
  # Initialize a SWORD Connection based on the config params.
  #
  # This only *initializes* a SwordClient::Connection; it
  # doesn't connect to the SWORD Server yet.

  def initialize(config = {})

    puts "Loading up with #{config.inspect}"
    # Load some default config (this is basically a reverse_merge with the block)
    @config = config.merge( "service_doc_url" => "http://localhost:3000/sword-app/servicedocument", "username" => nil, "password" => nil ) {|key, oldval, newval| oldval}

    # Check for Service Document URL (service_doc_url)
    if !@config['service_doc_url'] or @config['service_doc_url'].empty?
      raise SwordException, "A 'service_doc_url' is required."
    end

    #build our connection params from configurations
    params = {}
    params[:debug_mode] = true if @config['debug_mode']
    params[:username] = @config['username'] if @config['username'] and !@config['username'].empty?
    params[:password] = @config['password'] if @config['password'] and !@config['password'].empty?

    #if using a proxy, we need to init proxy settings
    if @config['proxy_server'] and !@config['proxy_server'].empty?
      proxy_settings = {}
      proxy_settings[:server] = @config['proxy_server']
      proxy_settings[:port] = @config['proxy_port'] if @config['proxy_port'] and !@config['proxy_port'].empty?
      proxy_settings[:username] = @config['proxy_username'] if @config['proxy_username'] and !@config['proxy_username'].empty?
      proxy_settings[:password] =  @config['proxy_password'] if @config['proxy_password']and !@config['proxy_password'].empty?

      #add all our proxy settings to params
      params[:proxy_settings] = proxy_settings
    end

    #initialize our SWORD connection
    # (Note: this doesn't actually connect to SWORD, yet!)
    @connection = SwordClient::Connection.new(@config['service_doc_url'], params)
  end

  # get the details about the repo at the end of the connection
  def repository
    @repository ||= SwordClient::Repository.new(@connection)
  end

  # Posts a file to the SWORD connection for deposit.
  #   Paths are initialized based on config params.
  #
  # If deposit URL is unspecified, it posts to the 
  # default collection (if one is specified in config params)
  #
  # For a list of valid 'headers', see Connection.post_file()
  def post_file(file_path, deposit_url=nil, headers={})
    
    if deposit_url.nil?
      #post to default collection, if there is one
      default_col = get_default_collection
      deposit_url = default_col['deposit_url'] if default_col
    end
    
    #only post file if we have some sort of deposit url!
    if deposit_url and !deposit_url.empty?
      @connection.post_file(file_path, deposit_url, headers)
    else
      raise SwordException.new, "File '#{file_path}' could not be posted via SWORD as no deposit URL (or default collection) was specified!"
    end
  end

  # Retrieve collection hash for the Collection that has
  # specified (in config params) as the "default" collection
  # for all SWORD deposits.  This pulls the information from
  # the currently loaded Service Document.
  #
  # See SwordClient::ParsedServiceDoc for hash structure. 
  def get_default_collection
    
    # get our available collections
    colls = get_collections
   
    #locate our default collection, based on configs loaded from sword.yml
    default_collection = nil
    colls.each do |c|
      if @config['default_collection_url']
        default_collection = c if c['deposit_url'].to_s.strip == @config['default_collection_url'].strip
        break if default_collection #first matching collection wins!
      elsif @config['default_collection_name']
        default_collection = c if c['title'].to_s.strip.downcase == @config['default_collection_name'].strip.downcase
        break if default_collection #first matching collection wins!
      end
    end
    
    default_collection
  end

  # DEPRECATED

  # Retrieve array of available collections from the currently loaded
  # SWORD Service Document.  Each collection is represented by a
  # hash of attributes.
  #
  # Caches this array of collections for future requests using same client.
  #
  # See SwordClient::ParsedServiceDoc for hash structure.
  def get_collections
    repository.collections
  end

  def get_repository_name
    repository.name
  end

  # Retrieve the SWORD Service Document for current repository.
  def service_document
    repository.service_document
  end

  # Retrieve and parse the SWORD Service Document for current connection.
  #
  # This returns a SwordClient::ParsedServiceDoc.  In addition, it caches
  # this parsed service document for future requests using same client.
  def parsed_service_document
   repository.parsed_service_document
  end

end

#load SwordClient sub-classes
require File.dirname(__FILE__) + '/sword_client/connection'
require File.dirname(__FILE__) + '/sword_client/service_doc_handler'
require File.dirname(__FILE__) + '/sword_client/repository'
require File.dirname(__FILE__) + '/sword_client/parsed_service_doc'
