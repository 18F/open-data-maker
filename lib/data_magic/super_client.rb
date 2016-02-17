require 'forwardable'

module DataMagic
  class SuperClient
    attr_reader :client, :options

    def initialize(client, options)
      @client = client
      @options = options
    end

    def create_index
      DataMagic.create_index unless config.index_exists?
    end

    def refresh_index
      client.indices.refresh index: index_name
    end

    def creating?
      options[:nest] == nil
    end

    def allow_skips?
      options[:nest][:parent_missing] == 'skip'
    end

    def index_name
      config.scoped_index_name
    end

    def config
      DataMagic.config
    end

    extend Forwardable

    def_delegators :client, :index, :update
  end
end
