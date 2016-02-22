module DataMagic
  module Load
    class YamlData
      attr_reader :options, :s3_client

      def initialize(options)
        @options = options
        @s3_client = options[:s3]
      end

      def path(alt_path=nil)
        @path || assure_non_empty(alt_path) || default_path
      end

      def read(alt_path=nil)
        set_path(alt_path)
        raise ArgumentError, "unexpected scheme: #{scheme}" if !adapter
        adapter.read
      end

      private

      def adapter
        adapters.detect(&:can_handle?)
      end

      def adapters
        uri = URI(path)
        [Load::S3Adapter.new(uri, s3_client), Load::LocalAdapter.new(uri)]
      end

      def scheme
        URI(path).scheme
      end

      def set_path(path)
        @path = assure_non_empty(path) || default_path
      end

      def default_path
        options_path || env_path || global_default_path
      end

      def options_path
        assure_non_empty(options[:data_path])
      end

      def env_path
        assure_non_empty(ENV['DATA_PATH'])
      end

      def global_default_path
        DataMagic::DEFAULT_PATH
      end

      def assure_non_empty(value)
        return nil unless value && !value.empty?
        value
      end
    end
  end
end
