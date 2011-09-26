require File.dirname(__FILE__) + "/deposit/version"

# Deposit.configure do
#   sword(:harvard) do
#     name "Harvard Berkman Library"
#     service_doc_url "Things"
#     username "myuser"
#     password "thing"
#   end
# end

# then you can Deposit.deposit(:mit, hash_with_info) or Deposit.deposit_all.  that way we could make it asynchronous easier 

module Deposit
  require File.dirname(__FILE__) + "/deposit/sword_client"

  class <<self
    attr_accessor :repositories

    def configure(&blk)
      @repositories = {}

      @config = Configurator.new
      @config.instance_eval(&blk)
    end

    def deposit(repository_name, information) # information is what's needed to build the post
      @repositories[repository_name].deposit(info)
    end

    def deposit_all(information)
      @repositories.each do |key, repos|
        repos.deposit(info)
      end
    end
  end

  class Configurator
    def sword(name, &blk)
      c = ConfigBucket.new
      c.instance_eval(&blk)

      Deposit.repositories[name] = Deposit::SwordClient.new(c._attributes)
    end
  end

  class ConfigBucket
    def initialize
      @attributes = {}
    end

    def _attributes
      @attributes
    end

    def method_missing(method_name, *args)
      @attributes[method_name] = args.first
    end
  end
end
