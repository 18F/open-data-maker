require 'forwardable'

module DataMagic
  module Index
    class RowImporter
      attr_reader :row, :importer

      def initialize(row, importer)
        @row = row
        @importer = importer
      end

      def process
        log_row_start
        before_save
        save
        after_save
        log_row_end
      end

      def document
        @document ||= DocumentBuilder.create(row, importer.builder_data, config)
      end

      def repository
        @repository ||= Repository.new(importer.client, document)
      end

      private

      def log_row_start
        trigger("debug", "csv parsed") if importer.empty?
        trigger("info", "row #{importer.row_count}", document, 500) if importer.row_count % 500 == 0
        #trigger("info", "id", document.id)
        if document.id_empty?
          trigger("warn", "blank id")
          trigger("warn", "unique", config.data["unique"])
          trigger("warn", "in row", document, 255)
        end
      end

      def before_save
        importer.set_headers(document)
      end

      def save
        repository.save
      end

      def after_save
        importer.skipping(document.id) if repository.skipped?
        importer.increment
      end

      def log_row_end
        return if !importer.at_limit?
        trigger("info", "done now, limiting rows to #{importer.row_count}")
      end

      def config
        DataMagic.config
      end

      extend Forwardable

      def_delegators :importer, :trigger

      def self.process(*args)
        new(*args).process
      end
    end
  end
end
