require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe "DataMagic #search" do
  let (:expected) { {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => 	[]
          } }

  describe "with terms" do
    describe "default" do
      before (:all) do
        DataMagic.init(load_now: false)
        num_rows, fields = DataMagic.import_csv(address_data)
      end
      after(:all) do
        DataMagic.destroy
      end

      it "can find an attribute from an imported file" do
        result = DataMagic.search({name: "Marilyn"})
        expected["results"] = [{"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Burbank"}]
        expect(result).to eq(expected)
      end

      it "can find based on multiple attributes from an imported file" do
        result = DataMagic.search({name: "Paul", city:"Liverpool"})
        expected["results"] = [{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool"}]
        expect(result).to eq(expected)
      end

      it "supports pagination" do
        result = DataMagic.search({address: "Lane", page:1, per_page: 3})
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
        DataMagic.init(load_now: false)
        options = {}
        options[:fields] = {name: 'person_name', address: 'street'}
        options[:override_global_mapping] = {}
        num_rows, fields = DataMagic.import_csv(address_data, options)
        expect(fields.sort).to eq(options[:fields].values.sort)
      end
      after(:all) do
        DataMagic.destroy
      end

      it "can find an attribute from an imported file" do
        result = DataMagic.search({person_name: "Marilyn" })
        expected["results"] = [{"person_name" => "Marilyn", "street" => "1313 Mockingbird Lane"}]
        expect(result).to eq(expected)
      end


    end


  end
  describe "with geolocation" do
    before (:all) do
      ENV['DATA_PATH'] = './spec/fixtures/geo_no_files'
      DataMagic.init(load_now: false)
      options = {}
      options[:fields] = {lat: 'location.lat',
                          lon: 'location.lon',
                          city: 'city'}
      num_rows, fields = DataMagic.import_csv(geo_data, options)
    end
    after(:all) do
      DataMagic.destroy
    end

    it "#search can find an attribute" do
      sfo_location = { lat: 37.615223, lon:-122.389977 }
      DataMagic.logger.debug "sfo_location[:lat] #{sfo_location[:lat].class} #{sfo_location[:lat].inspect}"
      search_terms = {distance:"100mi", zip:"94102"}
      result = DataMagic.search(search_terms)
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
