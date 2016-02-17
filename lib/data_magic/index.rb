require_relative 'config'
require_relative 'document_builder'
require_relative 'builder_data'
require_relative 'output'
require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic
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

  class IndexClient
    attr_reader :client, :options

    def initialize(client, options)
      @client = client
      @options = options
    end

    def save(document)
      @skipped_last_document = false
      if creating?
        create(document)
      else
        update(document)
      end
    end

    def skipped_last_document?
      @skipped_last_document
    end

    private

    def create(document)
      client.index({
        index: index_name,
        id: document.id,
        type: 'document',
        body: document.data,
      })
    end

    def update(document)
      document.remove_ids
      if allows_skips?
        update_with_rescue(document)
      else
        update_without_rescue(document)
      end
    end

    def update_without_rescue(document)
      client.update({
        index: index_name,
        id: document.id,
        type: 'document',
        body: {doc: document.data},
      })
    end

    def update_with_rescue(document)
      update_with_rescue(document)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      @skipped_last_document = true
    end

    def creating?
      options[:nest] == nil
    end

    def allows_skips?
      options[:nest][:parent_missing] == 'skip'
    end

    def index_name
      config.scoped_index_name
    end

    def config
      DataMagic.config
    end
  end

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    self.create_index unless config.index_exists?
    es_index_name = self.config.scoped_index_name

    builder_data = BuilderData.new(data, options)
    builder_data.normalize!
    builder_data.log_metadata

    output = Output.new

    index_client = IndexClient.new(client, options)

    begin
      CSV.parse(
        builder_data.data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        # process row
        document = DocumentBuilder.create(row, builder_data, config)

        output.log(document)
        output.set_headers(document)

        logger.info "id: #{document.id.inspect}"
        if document.id_empty?
          logger.warn "unexpected blank id for "+
                      "unique: #{config.data['unique'].inspect} "+
                      "in row: #{document.preview(255)}"
        end

        index_client.save(document)
        output.skipping(document.id) if index_client.skipped_last_document?

        #if options[:nest] == nil  #first time or normal case
          #client.index({
            #index: es_index_name,
            #id: document.id,
            #type: 'document',
            #body: document.data,
          #})
        #else
          #begin
            #document.remove_ids
            #client.update({
              #index: es_index_name,
              #id: document.id,
              #type: 'document',
              #body: {doc: document.data},
            #})
          #rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
            #if options[:nest][:parent_missing] == 'skip'
              #output.skipping(id)
            #else
              #raise e
            #end
          #end
        #end

        output.increment

        if options[:limit_rows] && output.row_count == options[:limit_rows]
          output.log_limit
          break
        end
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
