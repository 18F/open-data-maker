require_relative 'config'

module DataMagic
  module Index

    # data could be a String or an io stream
    def import_csv(index_name, data, options={})
      Config.logger.debug "Indexing data -- index_name: #{index_name}, data: #{data}, options: #{options}"
      additional_fields = options[:override_global_mapping]
      additional_fields ||= Config.global_mapping
      additional_data = options[:add_data]
      Config.logger.debug "additional_data: #{additional_data.inspect}"

      data = data.read if data.respond_to?(:read)
      index_name = create_index_if_needed(index_name)

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
          #Config.logger.debug "indexing: #{row.inspect}"
          client.index index: index_name, type:'document', body: row
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
      client.indices.refresh index: index_name if num_rows > 0

      return [num_rows, fields ]
    end

    def import_all(options = {})
      Config.logger.debug "--- import_all --"
      directory_path = options[:data_path] || Config.data_path
      index = Config.load(directory_path)
      Config.files.each do |filepath|
        fname = filepath.split('/').last
        Config.logger.debug "indexing #{fname} config:#{Config.additional_data_for_file(fname).inspect}"
        options[:add_data] = Config.additional_data_for_file(fname)
        #begin
          Config.logger.debug "reading #{filepath}"
          data = Config.read_path(filepath)
          rows, fields = DataMagic.import_csv(index, data, options)
          Config.logger.debug "imported #{rows} rows"
        #rescue Exception => e
        #  Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
        #end
      end
    end

    def self.delete(index_name)
      Config.load_if_needed
      index_name = DataMagic.scoped_index_name(index_name)
      Stretchy.delete index_name
      DataMagic.client.indices.clear_cache
      # TODO: remove some entries from @@files
    end

  end # module Index
end # module DataMagic
