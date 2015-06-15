class InvalidData < StandardError
end


class DataMagic
  class << self
    require 'csv'

    def import_csv(index_name, datafile)
      data = datafile.read

      fields = nil
      num_rows = 0
      begin
        CSV.parse(data, headers:true, :header_converters=> lambda {|f| f.strip.to_sym }) do |row|
          fields ||= row.headers
          row = row.to_hash
          num_rows += 1
        end
      rescue Exception => e
        puts "row #{num_rows}: #{e.message}"
        num_rows -=1
      end

      raise InvalidData, "invalid file format or zero rows" if num_rows == 0
      return [num_rows, fields ]
    end

    def search(index_name, query)
    end
  end
end
