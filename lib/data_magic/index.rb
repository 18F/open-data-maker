require_relative 'config'
require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic

  def self.parse_nested(document, options)
    new_doc = {}
    nest_options = options[:nest]
    if nest_options
      #logger.info "nest: #{nest_options.to_yaml}"
      #logger.info "add to document: #{document.inspect[0..255]}"
      key = nest_options['key']
      new_doc[key] = {}

      id = document['id']
      new_doc['id'] = id unless id.nil?

      nest_options['contents'].each do |item_key|
        #logger.info "adding item #{item_key}"
        new_doc[key][item_key] = document[item_key]
      end
    end
    #logger.info "here it is: #{new_doc}"
    new_doc
  end

  # parse a row from a csv file, returns a nested document
  def self.parse_row(row, fields, options, additional)
    row = row.to_hash
    #logger.info "fields #{fields.inspect}"
    row = map_field_names(row, fields, options) unless fields.empty?
    map_field_types(row, config.column_field_types) unless config.column_field_types.empty?
    row = row.merge(additional) if additional
    document = NestedHash.new.add(row)
    document = parse_nested(document, options) if options[:nest]
    document = document.select {|key, value| options[:only].include?(key) } unless options[:only].nil?
    document
  end

  # return the unique identifier, optionally remove from row
  def self.get_id(row, options={})
    if config.data['unique'].length > 0
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

    logger.info "  new_field_names: #{new_field_names.inspect[0..500]}"
    logger.info "  options: #{options.reject { |k,v| k == :mapping }.to_yaml}"
    logger.info "  additional_data: #{additional_data}"

    begin
      CSV.parse(
        data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        doc = parse_row(row, new_field_names, options, additional_data)
        headers ||= doc.keys.map(&:to_s)  # does this only return top level fields?
        if num_rows % 500 == 0
          logger.info "indexing rows: #{num_rows}..."
        end
        if num_rows == 0
          logger.info "row#{num_rows} -> #{doc.inspect[0..500]}"
          logger.info "id: #{get_id(doc).inspect}"
        end
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
              logger.info "missing parent id:#{id} -- skipping"
            else
              raise e
            end
          end
        end
        num_rows += 1
        if options[:limit_rows] and num_rows == options[:limit_rows]
          logger.info "done now"
          break
        end
      end

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
    create_index es_index_name, config.field_types
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
      raise ArgumentError, "column header missing for: #{value}" if key.nil?
      new_key = new_fields[key.to_sym] || new_fields[key.to_s]
      #logger.info "key: #{key.inspect}, new_key:#{new_key.inspect}"
      if new_key
        value = value.to_f if new_key.include? "location"
        mapped[new_key] = value
      elsif options[:columns] == 'all'
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
