module DataMagic
  module Index
    class Document
      attr_reader :data, :id

      def initialize(data)
        @data = data
        @id ||= calculate_id
      end

      def remove_ids
        config.data['unique'].each { |key| data.delete key }
      end

      def headers
        data.keys.map(&:to_s) # does this only return top level fields?
      end

      def preview(n=500)
        data.inspect[0..n]
      end

      def id_empty?
        id && id.empty?
      end

      private

      def calculate_id
        return nil if config.data['unique'].length == 0
        config.data['unique'].map { |field| data[field] }.join(':')
      end

      def config
        DataMagic.config
      end
    end
  end
end
