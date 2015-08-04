require 'csv'

class Zipcode
  @@zipcode_hash = {}
  def Zipcode.init
    parsed_file = CSV.read(Padrino.root('lib', 'zipcode', 'us_zipcodes.txt'), { :col_sep => "\t" })
    converted_zipcodes = {}
    parsed_file.each do |row|
      zipcode = row[1]
      lat = row[9]
      lon = row[10]
      converted_zipcodes[zipcode] = {'lat': lat, 'lon': lon}
    end
    @@zipcode_hash = converted_zipcodes
  end

  def Zipcode.latlon(zipcode)
    @@zipcode_hash[zipcode]
  end
end
