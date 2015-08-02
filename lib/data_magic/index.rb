require_relative 'config'
require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic

  def self.parse_row(row, fields, options, additional)
    row = row.to_hash
    row = map_field_names(row, fields, options) unless fields.empty?
    map_field_types(row, config.field_types) unless config.field_types.empty?
    row = row.merge(additional) if additional
    row = NestedHash.new.add(row)
    row
  end

  def self.get_id(row)
    if config.data['unique'].length > 0
      result = config.data['unique'].map { |field| row[field] }.join(':')
      if result.empty?
        logger.warn "unexpected blank id for "+
                    "unique: #{config.data['unique'].inspect} "+
                    "in row: #{row.inspect[0..255]}"
      end
    else
      result = nil
    end
    result
  end

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    es_index_name = self.create_index
    Config.logger.debug "Indexing data -- index_name: #{es_index_name}" #options: #{options}"
    additional_fields = options[:mapping] || {}
    additional_data = options[:add_data]
    Config.logger.debug "additional_data: #{additional_data.inspect}"

    data = data.read if data.respond_to?(:read)

    if options[:force_utf8]
      data = data.encode('UTF-8', invalid: :replace, replace: '')
    end

    new_field_names = options[:fields] || {}
    new_field_names = new_field_names.merge(additional_fields)
    num_rows = 0
    headers = nil
    begin
      CSV.parse(
        data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        row = parse_row(row, new_field_names, options, additional_data)
        headers ||= row.keys.map(&:to_s)
        if num_rows == 0
          logger.info "first row: #{row.inspect[0..500]}"
          logger.info "id: #{get_id(row).inspect}"
        end
        client.index({
          index: es_index_name,
          id: get_id(row),
          type: 'document',
          body: row,
        })
        if num_rows % 500 == 0
          logger.info "indexing rows: #{num_rows}..."
        end
        num_rows += 1
      end

    rescue Exception => e
      Config.logger.error e.message
      rows = []
    end

    raise InvalidData, "invalid file format or zero rows" if num_rows == 0
    client.indices.refresh index: es_index_name

    return [num_rows, headers]
  end

  def self.import_with_dictionary(options = {})
    start_time = Time.now
    Config.logger.debug "--- import_with_dictionary, starting at #{start_time}"
    field_mapping = {}

    # field_name: name we want as the json key
    # field_mapping[column_name] = field_name
    self.config.dictionary.each do |field_name, info|
      case info
        when String
          field_mapping[info] = field_name
        when Hash
          column_name = info['source']
          field_mapping[column_name] = field_name
        else
          Config.logger.warn("unexpected dictionary field info " +
            "for #{field_name}: #{info.inspect} -- expected String or Hash")
      end
    end
    #logger.debug("field_mapping: #{field_mapping.inspect}")
    options[:mapping] = field_mapping
    options = options.merge(config.data['options'])

    es_index_name = self.config.load_datayaml(options[:data_path])
    logger.info "creating #{es_index_name}"   # TO DO: fix #14
    self.create_index es_index_name, config.field_types
    logger.info "files: #{self.config.files}"
    self.config.files.each do |filepath|
      fname = filepath.split('/').last
      logger.debug "indexing #{fname} file config:#{self.config.additional_data_for_file(fname).inspect}"
      options[:add_data] = self.config.additional_data_for_file(fname)
      begin
        logger.debug "reading #{filepath}"
        data = config.read_path(filepath)
        rows, _ = DataMagic.import_csv(data, options)
        logger.debug "imported #{rows} rows"
      rescue Exception => e
       Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      end
    end
    logger.debug "indexing complete: #{distance_of_time_in_words(Time.now, start_time)}"
  end # import_with_dictionary

private
  # row: a hash  (keys may be strings or symbols)
  # new_fields: hash current_name : new_name
  # returns a hash (which may be a subset of row) where keys are new_name
  #         with value of corresponding row[current_name]
  def self.map_field_names(row, new_fields, options={})
    mapped = {}
    row.each do |key, value|
      new_key = new_fields[key.to_sym] || new_fields[key.to_s]
      if new_key
        value = value.to_f if new_key.include? "location"
        mapped[new_key] = value
      elsif options[:import] == 'all'
        mapped[key] = value
      end
    end
    mapped
  end

  # row: a hash  (keys may be strings or symbols)
  # field_types: hash field_name : type (float, integer, string)
  # returns a hash where values have been coerced to the new type
  def self.map_field_types(row, field_types = {})
    row.each do |key, value|
      type = field_types[key.to_sym] || field_types[key.to_s]
      #logger.info "key: #{key} type: #{type}"
      case type
        when "float"
          row[key] = value.to_f
        when "integer"
          row[key] = value.to_i
        when "string"
          row[key] = value.to_s
      end
    end
    row
  end

end # module DataMagic
