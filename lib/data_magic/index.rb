require_relative 'config'

module DataMagic

  def self.get_id(index, row)
    config.data['unique'].empty? ? nil : search_id(index, row)
  end

  def self.unique_query(row)
    terms = config.data['unique'].map { |unique| ["_unique.#{unique}", row[unique]] }
    query = Hashie::Mash.new
    query.filtered!.query!.match_all = {}
    query.filtered!.filter!.nested!.path = '_unique'
    query.filtered!.filter!.nested!.filter!.bool!.must = [{term: Hash[terms]}]
    query.to_hash
  end

  def self.search_id(index, row)
    query = unique_query(row)
    doc = {
      index: index,
      body: {
        query: query,
        size: 1,
      },
    }
    hits = client.search(doc)['hits']
    hits['total'] > 0 ? hits['hits'][0]['_id'] : nil
  end

  def self.get_unique(row)
    pairs = config.data['unique'].map { |unique| [unique, row[unique]] }
    Hash[pairs]
  end

  def self.parse_rows(data, fields, additional)
    parsed = CSV.parse(
      data,
      headers: true,
      header_converters: lambda { |str| str.strip.to_sym }
    )
    rows = parsed.map { |row| parse_row(row, fields, additional) }
    config.data['unique'].empty? ? rows : rows.uniq { |row| get_unique(row) }
  end

  def self.parse_row(row, fields, additional)
    row = row.to_hash
    row = map_field_names(row, fields) unless fields.empty?
    row = row.merge(additional) if additional
    row['_unique'] = get_unique(row)
    row = NestedHash.new.add(row)
    row
  end

  # data could be a String or an io stream
  def self.import_csv(data, options = {})
    es_index_name = self.create_index_if_needed
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
      rows = parse_rows(data, new_field_names, additional_data)
    rescue Exception => e
      Config.logger.error e.message
      rows = []
    end
    client.indices.refresh index: es_index_name
    rows.each { |row|
      client.index({
        index: es_index_name,
        id: get_id(es_index_name, row),
        type: 'document',
        body: row,
      })
    }

    raise InvalidData, "invalid file format or zero rows" if rows.length == 0
    client.indices.refresh index: es_index_name

    fields = rows.map(&:keys).flatten.uniq
    fields.delete('_unique')

    return [rows.length, fields]
  end

  def self.import_with_dictionary(options = {})
    Config.logger.debug "--- import_with_dictionary --"
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
    Config.logger.debug("field_mapping: #{field_mapping.inspect}")
    options[:mapping] = field_mapping

    es_index_name = self.config.load_datayaml(options[:data_path])
    # logger.info "deleting old index #{es_index_name}"   # TO DO: fix #14
    # Stretchy.delete es_index_name
    # logger.info "creating #{es_index_name}"   # TO DO: fix #14
    self.create_index_if_needed es_index_name
    logger.info "files: #{self.config.files}"
    self.config.files.each do |filepath|
      fname = filepath.split('/').last
      Config.logger.debug "indexing #{fname} file config:#{self.config.additional_data_for_file(fname).inspect}"
      options[:add_data] = self.config.additional_data_for_file(fname)
      #begin
        Config.logger.debug "reading #{filepath}"
        data = config.read_path(filepath)
        rows, fields = DataMagic.import_csv(data, options)
        Config.logger.debug "imported #{rows} rows"
      #rescue Exception => e
      #  Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      #end
    end
  end
end # module DataMagic
