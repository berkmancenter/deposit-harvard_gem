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
# The minimum connection options you must specify depend
# on the location of your SWORD server (and whether it requires
# authentication).  Minimally, you likely need to change
# "SWORD Service Document URL" and "SWORD Server Default Login"
#
# Example production configuration (RAILS_ROOT/config/sword.yml)
#
# d = Deposit::SwordClient.new( 'service_doc_url' => 'http://localhost:8080/sword-app/servicedocument',
#                               'username' => 'bob', 'password' => 'sekret')
#
# If you requirea Proxy to connect to the SWORD server, you must specify it as well, like so:
#  
# d = Deposit::SwordClient.new( 'service_doc_url' => 'http://localhost:8080/sword-app/servicedocument',
#                               'username' => 'bob', 'password' => 'sekret', 'proxy_server' => 'my.proxy.edu')
#
# Other proxy-related options you can include in the call to Deposit::SwordClient.new are 'proxy_port',
# 'proxy_username', and 'proxy_password'.
#
# If you specify a 'default_collection_url' or a 'default_collection_name', it should
# correspond to the Deposit URL of one of the collections returned by the Service Document URL
# you have specified.  Generally you specify either a 'default_collection_url' OR a 'default_collection_name',
# but not both.  The SwordClient will pick the first match it finds if both are specified, checking the URL
# before the name.

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

    # build our connection params from configurations
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
    @connection = Connection.new(@config['service_doc_url'], params)
  end

  # get the details about the repo at the end of the connection
  def repository
    @repository ||= Repository.new(@connection)
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
    params = {}
    ['default_collection_url', 'default_collection_name'].each do |key|
      params[key] = @config[key] if @config[key]
    end
    repository.default_collection(params)
  end

  # DEPRECATED

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

# load SwordClient sub-classes
Dir[File.dirname(__FILE__) + '/sword_client/*.rb'].each {|file| require file }
