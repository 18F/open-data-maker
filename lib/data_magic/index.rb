require_relative 'config'
require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic

  def self.parse_rows(data, fields, options, additional)
    parsed = CSV.parse(
      data,
      headers: true,
      header_converters: lambda { |str| str.strip.to_sym }
    )
    parsed.map { |row| parse_row(row, fields, options, additional) }
  end

  def self.parse_row(row, fields, options, additional)
    row = row.to_hash
    row = map_field_names(row, fields, options) unless fields.empty?
    row = row.merge(additional) if additional
    row = NestedHash.new.add(row)
    row
  end

  def self.get_id(row)
    config.data['unique'].length > 0 ?
      config.data['unique'].map { |field| row[field] }.join(':') :
      nil
  end

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    es_index_name = self.create_index
    Config.logger.debug "Indexing data -- index_name: #{es_index_name}, options: #{options}"
    additional_fields = options[:mapping] || {}
    additional_data = options[:add_data]
    Config.logger.debug "additional_data: #{additional_data.inspect}"

    data = data.read if data.respond_to?(:read)

    if options[:force_utf8]
      data = data.encode('UTF-8', invalid: :replace, replace: '')
    end

    new_field_names = options[:fields] || {}
    new_field_names = new_field_names.merge(additional_fields)
    begin
      rows = parse_rows(data, new_field_names, options, additional_data)
    rescue Exception => e
      Config.logger.error e.message
      rows = []
    end
    rows.each { |row|
      client.index({
        index: es_index_name,
        id: get_id(row),
        type: 'document',
        body: row,
      })
    }

    raise InvalidData, "invalid file format or zero rows" if rows.length == 0
    client.indices.refresh index: es_index_name

    fields = rows.map(&:keys).flatten.uniq
    return [rows.length, fields]
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
    logger.debug("field_mapping: #{field_mapping.inspect}")
    options[:mapping] = field_mapping
    options = options.merge(config.data['options'])

    es_index_name = self.config.load_datayaml(options[:data_path])
    logger.info "creating #{es_index_name}"   # TO DO: fix #14
    self.create_index es_index_name
    logger.info "files: #{self.config.files}"
    self.config.files.each do |filepath|
      fname = filepath.split('/').last
      logger.debug "indexing #{fname} file config:#{self.config.additional_data_for_file(fname).inspect}"
      options[:add_data] = self.config.additional_data_for_file(fname)
      #begin
        logger.debug "reading #{filepath}"
        data = config.read_path(filepath)
        rows, _ = DataMagic.import_csv(data, options)
        logger.debug "imported #{rows} rows"
      #rescue Exception => e
      #  Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      #end
    end
    logger.debug "indexing complete: #{distance_of_time_in_words(Time.now, start_time)}"
  end # import_with_dictionary

end # module DataMagic
