require_relative 'config'
require_relative 'document_builder'
require_relative 'builder_data'
require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic

  # return the unique identifier, optionally remove from row
  def self.get_id(row, options={})
    if config.data['unique'].length > 0
      #logger.info "config.data['unique'] #{config.data['unique'].inspect}"
      #logger.info "row #{row}"
      result = config.data['unique'].map { |field| row[field] }.join(':')
      #logger.info "id: #{result.inspect}"
      if result.empty?
        logger.warn "unexpected blank id for "+
                    "unique: #{config.data['unique'].inspect} "+
                    "in row: #{row.inspect[0..255]}"
      end
      if options[:remove]
        config.data['unique'].each { |key| row.delete key }
      end
    else
      result = nil
    end
    result
  end

  class Output
    attr_reader :row_count, :headers, :skipped, :options

    def initialize(options)
      @options = options
      @row_count = 0
      @skipped = []
    end

    def set_headers(doc)
      return if headers
      @headers = doc.keys.map(&:to_s) # does this only return top level fields?
    end


    def skipping(id)
      skipped << id
    end

    def increment
      @row_count += 1
    end

    def at_limit?
      return false if !options[:limit_rows]
      row_count == options[:limit_rows]
    end

    def validate!
      raise InvalidData, "zero rows" if empty?
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

    def log_0(doc)
      logger.debug "csv parsed"
      logger.info "row#{row_count} -> #{doc.inspect[0..500]}"
      logger.info "id: #{DataMagic.get_id(doc).inspect}"
    end

    def log_marker
      logger.info "indexing rows: #{row_count}..."
    end
  end

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    self.create_index unless config.index_exists?
    es_index_name = self.config.scoped_index_name

    builder_data = BuilderData.new(data, options)
    builder_data.normalize!
    builder_data.log_metadata

    output = Output.new(options)

    begin
      CSV.parse(
        builder_data.data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        # process row
        doc = DocumentBuilder.build(row, builder_data, config)

        output.log(doc)
        output.set_headers(doc)

        if options[:nest] == nil  #first time or normal case
          client.index({
            index: es_index_name,
            id: get_id(doc),
            type: 'document',
            body: doc,
          })
        else
          begin
            #logger.info "UPDATE #{doc}"
            id = get_id(doc, remove: true)
            client.update({
              index: es_index_name,
              id: id,
              type: 'document',
              body: {doc: doc},
            })
          rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
            if options[:nest][:parent_missing] == 'skip'
              output.skipping(id)
            else
              raise e
            end
          end
        end

        output.increment
        output.log_limit
        break if output.at_limit?
      end
    rescue InvalidData => e
      Config.logger.error e.message
      raise InvalidData, "invalid file format" if output.row_count == 0
    end

    output.validate!

    client.indices.refresh index: es_index_name
    logger.info "done: #{output.row_count} rows"
    return [output.row_count, output.headers]
  end

  def self.import_with_dictionary(options = {})
    start_time = Time.now
    Config.logger.debug "--- import_with_dictionary, starting at #{start_time}"

    #logger.debug("field_mapping: #{field_mapping.inspect}")
    options[:mapping] = config.field_mapping
    options = options.merge(config.options)

    es_index_name = self.config.load_datayaml(options[:data_path])
    unless config.index_exists?(es_index_name)
      logger.info "creating #{es_index_name}"   # TO DO: fix #14
      create_index es_index_name, config.field_types
    end

    logger.info "files: #{self.config.files}"
    config.files.each_with_index do |filepath, index|
      fname = filepath.split('/').last
      logger.debug "indexing #{fname} #{index} file config:#{config.additional_data_for_file(index).inspect}"
      options[:add_data] = config.additional_data_for_file(index)
      options[:only] = config.info_for_file(index, :only)
      options[:nest] = config.info_for_file(index, :nest)
      begin
        logger.debug "*"*40
        logger.debug "*    #{filepath}"
        logger.debug "*"*40
        data = config.read_path(filepath)
        rows, _ = DataMagic.import_csv(data, options)
        logger.debug "imported #{rows} rows"
      rescue DataMagic::InvalidData => e
       Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      end
    end
    end_time = Time.now
    logger.debug "indexing complete: #{distance_of_time_in_words(end_time, start_time)}"
    logger.debug "duration: #{end_time - start_time}"
  end # import_with_dictionary

private
  def self.valid_types
    %w[integer float string literal name autocomplete boolean]
  end

end # module DataMagic
