module DataMagic
  module Load
    class YamlData
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def path
        options_path || env_path || default_path
      end

      private

      def options_path
        assure_non_empty(options[:data_path])
      end

      def env_path
        assure_non_empty(ENV['DATA_PATH'])
      end

      def default_path
        DataMagic::DEFAULT_PATH
      end

      def assure_non_empty(value)
        return nil unless value && !value.empty?
        value
      end
    end
  end
end
