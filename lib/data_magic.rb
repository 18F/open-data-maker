

class DataMagic
  class InvalidData < StandardError
  end

  require 'elasticsearch'
  @@client = Elasticsearch::Client.new log: true

  class << self
    require 'csv'

    def client
      @@client
    end

    def scoped_index_name(index_name)
      env = ENV['RACK_ENV']
      "#{env}-#{index_name}"
    end

    def delete_all
      client.indices.delete index: '_all'
      client.indices.clear_cache
    end

    def delete_index(index_name)
      index_name = scoped_index_name(index_name)
      client.indices.delete index: index_name
      client.indices.clear_cache
    end

    def import_csv(index_name, datafile, options={})
      unless datafile.respond_to?(:read)
        raise ArgumentError, "can't read datafile #{datafile.inspect}"
      end
      index_name = scoped_index_name(index_name)
      data = datafile.read

      if options[:force_utf8]
        data = data.encode('UTF-8', invalid: :replace, replace: '')
      end

      fields = nil
      num_rows = 0
      begin
        CSV.parse(data, headers:true, :header_converters=> lambda {|f| f.strip.to_sym }) do |row|
          fields ||= row.headers
          row = row.to_hash
          client.index index:index_name, type:'document', body: row
          num_rows += 1
        end
      rescue Exception => e
        puts "row #{num_rows}: #{e.message}"
      end

      raise InvalidData, "invalid file format or zero rows" if num_rows == 0

      client.indices.refresh index: index_name if num_rows > 0
      return [num_rows, fields ]
    end

    def search(index_name, query)
      index_name = scoped_index_name(index_name)

      full_query = {index: index_name, body: query}
      result = client.search full_query
      hits = result["hits"]
      hits["hits"].map {|hit| hit["_source"]}
    end
  end
end
