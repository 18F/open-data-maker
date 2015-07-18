require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe DataMagic do
  context "config" do
    before do
      DataMagic::Config.init
    end

    after do
      DataMagic::Index.delete('city-data')
    end

    it "has config data" do
      default_config = {"version"=>"cities100-2010", "index"=>"city-data", "api"=>"cities", "global_mapping"=>{"USPS"=>"state", "NAME"=>"name", "POP10"=>"population", "INTPTLAT"=>"location.lat", "INTPTLONG"=>"location.lon"}, "files"=>{"cities100.csv"=>{}}}
      expect(DataMagic::Config.data).to eq(default_config)
    end

    it "has default page size" do
      expect(DataMagic::Config.page_size).to eq(10)
    end

    describe "Config.new?" do   #rename ... or do this in load_config or something
      it "should be true if config has never been (explicitly) loaded" do
        # config is loaded by default
        expect(DataMagic::Config.new?('city-data')).to be true
      end
      context "after loading config" do
        before do
        DataMagic::Config.load("./spec/fixtures/import_all")
        end
        it "should be true" do
          expect(DataMagic::Config.new?('city-data')).to be true
        end
        it "twice should be false" do
          DataMagic::Config.new?('city-data')
          expect(DataMagic::Config.new?('city-data')).to be false
        end

      end
    end
  end



  describe "#search" do
    let (:expected) { {
              "total" => 1,
              "page" => 0,
              "per_page" => 10,
              "results" => 	[]
            } }

    describe "with terms" do
      describe "default" do
        before (:all) do
          num_rows, fields = DataMagic.import_csv('people', address_data, override_global_mapping:{})
        end

        after(:all) do
          DataMagic::Index.delete('people')
        end

        it "can find an attribute from an imported file" do
          result = DataMagic.search({name: "Marilyn"}, index: 'people')
          expected["results"] = [{"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Burbank"}]
          expect(result).to eq(expected)
        end

        it "can find based on multiple attributes from an imported file" do
          result = DataMagic.search({name: "Paul", city:"Liverpool"}, index: 'people')
          expected["results"] = [{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool"}]
          expect(result).to eq(expected)
        end

        it "supports pagination" do
          result = DataMagic.search({address: "Lane", page:1, per_page: 3}, index: 'people')
          expected["results"] = [{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool"}]
          expected = {"total"=>4, "page"=>1, "per_page"=>3,
              "results"=>[{"name"=>"Marilyn", "address"=>"1313 Mockingbird Lane", "city"=>"Burbank"},
                          {"name"=>"Peter", "address"=>"66 Parker Lane", "city"=>"New York"},
                          {"name"=>"Paul", "address"=>"15 Penny Lane", "city"=>"Liverpool"}]}

          expect(result["per_page"]).to eq(3)
          expect(result["page"]).to eq(1)
          expect(result["results"].length).to eq(3)
        end


      end
      describe "with mapping" do
        before (:all) do
          options = {}
          options[:fields] = {name: 'person_name', address: 'street'}
          options[:override_global_mapping] = {}
          num_rows, fields = DataMagic.import_csv('people', address_data, options)
          expect(fields.sort).to eq(options[:fields].values.sort)
        end

        after(:all) do
          DataMagic::Index.delete('people')
        end

        it "can find an attribute from an imported file" do
          result = DataMagic.search({person_name: "Marilyn" }, index: 'people')
          expected["results"] = [{"person_name" => "Marilyn", "street" => "1313 Mockingbird Lane"}]
          expect(result).to eq(expected)
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
        DataMagic::Index.delete('places')
      end

      it "#search can find an attribute" do
        sfo_location = { lat: 37.615223, lon:-122.389977 }
        DataMagic.logger.debug "sfo_location[:lat] #{sfo_location[:lat].class} #{sfo_location[:lat].inspect}"
        search_terms = {distance:"100mi", zip:"94102"}
        result = DataMagic.search(search_terms, index:'places')
        result["results"] = result["results"].sort_by { |k| k["city"] }
        expected["results"] = [
          {"city" => "San Francisco", "location"=>{"lat"=>37.727239, "lon"=>-123.032229}},
          {"city" => "San Jose",      "location"=>{"lat"=>37.296867, "lon"=>-121.819306}}
        ]
        expected["total"] = expected["results"].length
        expect(result).to eq(expected)
      end

    end

  end



end
