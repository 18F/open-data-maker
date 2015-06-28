require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe DataMagic do
  describe "#import_csv" do
    describe "with errors" do
      it "throws error if datafile doesn't respond to read" do
        expect{DataMagic.import_csv('test-index', nil)}.to raise_error(ArgumentError)
      end
      describe "while reading" do
        after(:each) do
          DataMagic.delete_index('test-index')
        end

        it "throws errors for bad format" do
          data = StringIO.new("not a csv file")
          expect{DataMagic.import_csv('test-index', data)}.to raise_error(DataMagic::InvalidData)
        end

        it "stops importing when invalid UTF-8 chars are found" do
          expect{
            File.open('./spec/fixtures/invalid_utf8.csv') do |f|
              num_rows, fields = DataMagic.import_csv('test-index', f)
              expect(num_rows).to eq(0)
              # note: with some files it imports some data
              # in that case an exception won't be raised, but haven't been able
              # to repro as a test case
            end
          }.to raise_error(DataMagic::InvalidData)
        end

        it "allows importing invalid utf8 with force_utf8 option" do
          real_num_rows = File.read('./spec/fixtures/invalid_utf8.csv').lines.count - 1
          File.open('./spec/fixtures/invalid_utf8.csv') do |f|
            reported_num_rows, fields = DataMagic.import_csv('test-index', f, force_utf8: true)
            expect(reported_num_rows).to eq(real_num_rows)
          end
        end
      end
    end
    it "reads file and reports number of rows and headers" do
      data_str = <<-eos
a,b
1,2
3,4
eos
      data = StringIO.new(data_str)
      num_rows, fields = DataMagic.import_csv('my-index', data)
      expect(num_rows).to be(2)
      expect(fields).to eq( [:a,:b] )

      DataMagic.delete_index('my-index')
    end
  end

  describe "#search" do
    describe "with terms" do
      describe "default" do
        before (:all) do
          num_rows, fields = DataMagic.import_csv('people', address_data)
        end

        after(:all) do
          DataMagic.delete_index('people')
        end

        it "can find an attribute from an imported file" do
          result = DataMagic.search({name: "Marilyn"}, index: 'people')
          expect(result).to eq([{"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Burbank"}])
        end

        it "can find based on multiple attributes from an imported file" do
          result = DataMagic.search({name: "Paul", city:"Liverpool"}, index: 'people')
          expect(result).to eq([{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool"}])
        end

      end
      describe "with mapping" do
        before (:all) do
          options = {}
          options[:fields] = {name: 'person_name', address: 'street'}
          num_rows, fields = DataMagic.import_csv('people', address_data, options)
          expect(fields.sort).to eq(options[:fields].values.sort)
        end

        after(:all) do
          DataMagic.delete_index('people')
        end

        it "can find an attribute from an imported file" do
          result = DataMagic.search({person_name: "Marilyn" }, index: 'people')
          expect(result).to eq([{"person_name" => "Marilyn", "street" => "1313 Mockingbird Lane"}])
        end


      end


    end
    describe "with geolocation" do
      before (:all) do
        options = {}
        options[:fields] = {lat: 'location.lat',
                            lon: 'location.lon',
                            city: 'city'}
        num_rows, fields = DataMagic.import_csv('places', geo_data, options)
      end

      after(:all) do
        DataMagic.delete_index('places')
      end

      it "can find an attribute from an imported file" do
        sfo_location = { lat: 37.615223, lon:-122.389977 }
        puts "sfo_location[:lat] #{sfo_location[:lat].class} #{sfo_location[:lat].inspect}"
        distance = "100mi"
        result = DataMagic.geo_search(sfo_location, distance, index:'places')
        result = result.sort_by { |k| k["city"] }

        expected = [
          {"city" => "San Francisco", "location"=>{"lat"=>37.727239, "lon"=>-123.032229}},
          {"city"=>"San Jose",        "location"=>{"lat"=>37.296867, "lon"=>-121.819306}}
        ]
        expect(result).to eq(expected)
      end

    end

  end


  describe "#import_all" do

    before(:all) do
      dir_path = './spec/fixtures/import_all'
      @csv_files = Dir.glob("#{dir_path}/**/*.csv")
                            .select { |entry| File.file? entry }
      DataMagic.import_all(dir_path)
    end
    after(:all) do
      DataMagic.delete_index('city-data')
    end

    it "can get list of imported csv files" do
      expect(DataMagic.files.sort).to eq(@csv_files.sort)
    end

    it "can get index name from api endpoint" do
      expect(DataMagic.find_index_for('cities')).to eq('city-data')
    end

    it "indexes files with yaml mapping" do
      result = DataMagic.search({name: "Chicago"}, api: 'cities')
      expect(result).to eq([{"state"=>"IL", "name"=>"Chicago", "population"=>"2695598", "latitude"=>"41.837551", "longitude"=>"-87.681844"}])
    end

  end
end
