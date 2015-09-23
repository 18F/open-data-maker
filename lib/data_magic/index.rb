require_relative 'config'
require_relative 'document_builder'
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

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    self.create_index unless config.index_exists?
    es_index_name = self.config.scoped_index_name

    additional_fields = options[:mapping] || {}
    additional_data = options[:add_data]
    Config.logger.debug "additional_data: #{additional_data.inspect}"

    data = data.read if data.respond_to?(:read)
    data.sub!("\xEF\xBB\xBF", "") # remove Byte Order Mark
    if options[:force_utf8]
      data = data.encode('UTF-8', invalid: :replace, replace: '')
    end

    new_field_names = options[:fields] || {}
    new_field_names = new_field_names.merge(additional_fields)
    num_rows = 0
    headers = nil

    logger.info "  new_field_names: #{new_field_names.inspect[0..500]}"
    logger.info "  options: #{options.reject { |k,v| k == :mapping }.to_yaml}"

    skipped = []
    begin
      CSV.parse(
        data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        logger.info "csv parsed" if num_rows == 0
        doc = DocumentBuilder.parse_row(row, new_field_names, config,  options, additional_data)
        if num_rows % 500 == 0
          logger.info "indexing rows: #{num_rows}..."
        end
        if num_rows == 0
          logger.info "row#{num_rows} -> #{doc.inspect[0..500]}"
          logger.info "id: #{get_id(doc).inspect}"
        end
        headers ||= doc.keys.map(&:to_s)  # does this only return top level fields?
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
              skipped << id
            else
              raise e
            end
          end
        end
        num_rows += 1
        if options[:limit_rows] and num_rows == options[:limit_rows]
          logger.info "done now, limiting rows to #{num_rows}"
          break
        end
      end

    logger.info "skipped (missing parent id): #{skipped.join(',')}" unless skipped.empty?
    rescue Exception => e
        if e.class == ArgumentError && e.message == "invalid byte sequence in UTF-8"
          Config.logger.error e.message
          raise InvalidData, "invalid file format" if num_rows == 0
          rows = []
        else
          raise e
        end
    end

    raise InvalidData, "zero rows" if num_rows == 0
    client.indices.refresh index: es_index_name
    logger.info "done: #{num_rows} rows"
    return [num_rows, headers]
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
        logger.info "*"*40
        logger.info "*    #{filepath}"
        logger.info "*"*40
        data = config.read_path(filepath)
        rows, _ = DataMagic.import_csv(data, options)
        logger.debug "imported #{rows} rows"
      rescue DataMagic::InvalidData => e
       Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      end
    end
    logger.debug "indexing complete: #{distance_of_time_in_words(Time.now, start_time)}"
  end # import_with_dictionary

private
  def self.valid_types
    %w[integer float string literal name autocomplete]
  end

end # module DataMagic
