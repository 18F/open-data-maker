require_relative 'config'

module DataMagic

  def self.get_id(index, row)
    config.data['unique'].empty? ? nil : search_id(index, row)
  end

  def self.search_id(index, row)
    terms = config.data['unique'].map { |unique| [unique, row[unique]] }
    query = Stretchy.query(type: 'document').where.terms(Hash[terms])
    doc = {
      index: index,
      body: {
        query: query.to_search,
        size: 1,
      },
    }
    hits = client.search(doc)['hits']
    hits['total'] > 0 ? hits['hits'][0]['_id'] : nil
  end

  # data could be a String or an io stream
  def self.import_csv(data, options={})
    es_index_name = self.create_index_if_needed
    Config.logger.debug "Indexing data -- index_name: #{es_index_name}, options: #{options}"
    additional_fields = options[:mapping] || {}
    additional_data = options[:add_data]
    Config.logger.debug "additional_data: #{additional_data.inspect}"

    data = data.read if data.respond_to?(:read)

    if options[:force_utf8]
      data = data.encode('UTF-8', invalid: :replace, replace: '')
    end

    fields = nil
    new_field_names = options[:fields] || {}
    new_field_names = new_field_names.merge(additional_fields)
    num_rows = 0
    begin
      CSV.parse(data, headers:true, :header_converters=> lambda {|f| f.strip.to_sym }) do |row|
        fields ||= row.headers
        row = row.to_hash
        row = map_field_names(row, new_field_names) unless new_field_names.empty?
        row = row.merge(additional_data) if additional_data
        row = NestedHash.new.add(row)
        #logger.debug "indexing: #{row.inspect}"
        client.index({
          index: es_index_name,
          id: get_id(es_index_name, row),
          type: 'document',
          refresh: true,
          body: row,
        })
        num_rows += 1
        if num_rows % 500 == 0
          print "#{num_rows}..."; $stdout.flush
        end
      end
    rescue Exception => e
      Config.logger.error "row #{num_rows}: #{e.message}"
    end

    raise InvalidData, "invalid file format or zero rows" if num_rows == 0

    fields = new_field_names.values unless new_field_names.empty?
    client.indices.refresh index: es_index_name if num_rows > 0

    return [num_rows, fields]
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
