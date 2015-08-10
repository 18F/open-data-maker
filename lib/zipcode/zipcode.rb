# Zipcode latitude and longitude data in us_zipcodes.txt
# provided by [GeoNames](http://www.geonames.org/)
# under under a Creative Commons Attribution 3.0 License:
# http://creativecommons.org/licenses/by/3.0/

# this code is in public domain (CC0 1.0)
# https://github.com/18F/open-data-maker/blob/dev/LICENSE.md

require 'csv'

class Zipcode
  @@zipcode_hash = nil

  def Zipcode.latlon(zipcode)
    zipcode = zipcode.to_s
    @@zipcode_hash ||= converted_zipcodes
    @@zipcode_hash[zipcode]
  end

File.expand_path("../us_zipcodes.txt", __FILE__)
  private
    def self.converted_zipcodes
      parsed_file = CSV.read(File.expand_path("../us_zipcodes.txt", __FILE__), { :col_sep => "\t" })
      zipcode_hash = {}
      parsed_file.each do |row|
        zipcode = row[1]
        lat = row[9].to_f
        lon = row[10].to_f
        zipcode_hash[zipcode] = {'lat': lat, 'lon': lon}
      end
      zipcode_hash
    end

end
