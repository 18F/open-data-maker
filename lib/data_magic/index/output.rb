module DataMagic
  module Index
    class Output
      attr_reader :row_count, :headers, :skipped

      def initialize
        @row_count = 0
        @skipped = []
      end

      def set_headers(doc)
        return if headers
        @headers = doc.headers
      end

      def skipping(id)
        skipped << id
      end

      def increment(count = 1)
        @row_count += count
      end

      def validate!
        raise DataMagic::InvalidData, "zero rows" if empty?
      end

      def empty?
        row_count == 0
      end

      def log(doc)
        log_0(doc) if empty?
        log_marker if row_count % 500 == 0
      end

      def log_skips
        return if skipped.empty?
        logger.info "skipped (missing parent id): #{skipped.join(',')}"
      end

      def log_limit
        logger.info "done now, limiting rows to #{row_count}"
      end

      private

      def log_0(document)
        logger.debug "csv parsed"
        logger.info "row#{row_count} -> #{document.preview}"
      end

      def log_marker
        logger.info "indexing rows: #{row_count}..."
      end
    end
  end
end
