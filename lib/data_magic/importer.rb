require 'forwardable'

module DataMagic
  class Importer
    attr_reader :raw_data, :options

    def initialize(raw_data, options)
      @raw_data = raw_data
      @options = options
    end

    def client
      @client ||= SuperClient.new(es_client, options)
    end

    def builder_data
      @builder_data ||= BuilderData.new(raw_data, options)
    end

    def output
      @output ||= Output.new
    end

    def setup
      client.create_index
      builder_data.normalize!
      log_setup
    end

    def finish!
      validate!
      refresh_index
      log_finish
    end

    def log_setup
      opts = options.reject { |k,v| k == :mapping }
      trigger("info", "options", opts)
      trigger("info", "new_field_names", new_field_names)
      trigger("info", "additional_data", additional_data)
    end

    def log_finish
      trigger("info", "skipped (missing parent id)", output.skipped) if !output.skipped.empty?
      trigger('info', "done #{row_count} rows")
    end

    def event_logger
      @event_logger ||= EventLogger.new(self)
    end

    def at_limit?
      options[:limit_rows] && row_count == options[:limit_rows]
    end

    extend Forwardable

    def_delegators :output, :set_headers, :skipping, :skipped, :increment, :row_count, :log_limit,
      :empty?, :validate!, :headers
    def_delegators :builder_data, :data, :new_field_names, :additional_data
    def_delegators :client, :refresh_index
    def_delegators :event_logger, :trigger

    private

    def es_client
      DataMagic.client
    end
  end
end
