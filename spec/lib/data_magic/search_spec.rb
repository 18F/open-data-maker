require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe "DataMagic #search" do
  let (:expected) do
    {
      "metadata" => {
        "total" => 1,
        "page" => 0,
        "per_page" => DataMagic::DEFAULT_PAGE_SIZE
      },
      "results" => 	[]
    }
  end

  describe "with terms" do
    describe "as strings" do
      before (:all) do
        ENV['DATA_PATH'] = './no-data'
        ENV['ALLOW_MISSING_YML'] = 'allow'
        DataMagic.init(load_now: false)
        num_rows, fields = DataMagic.import_csv(address_data)
      end
      after(:all) do
        ENV['ALLOW_MISSING_YML'] = ''
        DataMagic.destroy
      end

      it "can find document with one attribute" do
        result = DataMagic.search({name: "Marilyn"})
        expected["results"] = [{"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Springfield",
                                "age" => "14", "height" => "2"}]
        expect(result).to eq(expected)
      end

      it "can find document with multiple search terms" do
        result = DataMagic.search({name: "Paul", city:"Liverpool"})
        expected["results"] = [{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool",
                                "age" => "10", "height" => "142"}]
        expect(result).to eq(expected)
      end

      it "can find a document with a set of values delimited by commas" do
        result = DataMagic.search({name: "Paul,Marilyn"})
        expected['metadata']["total"] = 3
        expect(result["results"]).to include({"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Springfield",
                                              "age" => "14", "height" => "2"})
        expect(result["results"]).to include({"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool",
                                              "age" => "10", "height" => "142"})
        expect(result["results"]).to include({"name" => "Paul", "address" => "19 N Square", "city" => "Boston",
                                              "age" => "70", "height" => "55.2"})
      end

      it "can return a single attribute" do
        result = DataMagic.search({city: "Springfield"}, fields:[:address])
        expected["results"] = [
          {"address" => "1313 Mockingbird Lane"},
          {"address"=>"742 Evergreen Terrace"},
        ]
        expected['metadata']["total"] = 2
        DataMagic.logger.info "======= EXPECTED: #{expected.inspect}"
        result["results"] = result["results"].sort_by { |k| k["address"] }
        expect(result).to eq(expected)
      end

      it "can return a subset of attributes" do
        result = DataMagic.search({city: "Springfield"}, fields:[:address, :city])
        expected["results"] = [
          {"city"=>"Springfield", "address"=>"1313 Mockingbird Lane"},
          {"city"=>"Springfield", "address"=>"742 Evergreen Terrace"},
        ]
        result["results"] = result["results"].sort_by { |k| k["address"] }
        expected['metadata']["total"] = 2
        expect(result).to eq(expected)
      end

      describe "supports pagination" do
        it "can specify both page and page size" do
          result = DataMagic.search({ address: "Lane" }, page:1, per_page: 3)
          expect(result['metadata']["per_page"]).to eq(3)
          expect(result['metadata']["page"]).to eq(1)
          expect(result["results"].length).to eq(1)
        end

        it "can use a default page size" do
          result = DataMagic.search({}, page:1)
          expect(result['metadata']["per_page"]).to eq(DataMagic::DEFAULT_PAGE_SIZE)
          expect(result['metadata']["page"]).to eq(1)
          expect(result["results"].length).to eq(0)
        end
      end
    end

    describe "with mapping" do
      before (:all) do
        ENV['DATA_PATH']="./no-data"
        DataMagic.init(load_now: false)
        options = {}
        options[:fields] = {name: 'person_name', address: 'street'}
        options[:override_dictionary] = {}
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

  describe "with numeric data" do
    before (:all) do
      ENV['DATA_PATH'] = './spec/fixtures/numeric_data'
      ENV['ALLOW_MISSING_YML'] = 'allow'
      DataMagic.init(load_now: false)
      num_rows, fields = DataMagic.import_csv(address_data)
    end
    after(:all) do
        DataMagic.destroy
        ENV['ALLOW_MISSING_YML'] = ''
    end

    it "can correctly compute filtered statistics" do
      expected["metadata"]["total"] = 2
      result = DataMagic.search({city: "Springfield"}, command: 'stats', fields: ["age", "height", "address"],
                                metrics: ['max', 'avg'])
      result["results"] = result["results"].sort_by { |k| k["age"] }

      expected["results"] = []
      expected["aggregations"] = {
        "age" => { "max" => 70.0, "avg" => 42.0},
        "height" => {"max"=>142.0, "avg"=>72.0}
      }

      expect(result).to eq(expected)
    end

    it "can correctly compute unfiltered statistics" do
      expected["metadata"]["total"] = 2
      result = DataMagic.search({city: "Springfield"}, command: 'stats', fields: ["age", "height", "address"])
      result["results"] = result["results"].sort_by { |k| k["age"] }

      expected["results"] = []
      expected["aggregations"] = {
        "age"=>{
          "count"=>2, "min"=>14.0, "max"=>70.0, "avg"=>42.0, "sum"=>84.0, "sum_of_squares"=>5096.0, "variance"=>784.0, "std_deviation"=>28.0, "std_deviation_bounds"=>{"upper"=>98.0, "lower"=>-14.0}},
        "height"=>{
          "count"=>2, "min"=>2.0, "max"=>142.0, "avg"=>72.0, "sum"=>144.0, "sum_of_squares"=>20168.0, "variance"=>4900.0, "std_deviation"=>70.0, "std_deviation_bounds"=>{"upper"=>212.0, "lower"=>-68.0}
        }
      }

      expect(result["age"]).to eq(expected["age"])
      expect(result["height"]).to eq(expected["height"])
    end
  end

  describe "with geolocation" do
    before (:all) do
      ENV['DATA_PATH'] = './spec/fixtures/geo_no_files'
      DataMagic.init(load_now: false)
      ENV['ALLOW_MISSING_YML'] = 'allow'
      options = {}
      options[:fields] = {lat: 'location.lat',
                          lon: 'location.lon',
                          city: 'city'}
      num_rows, fields = DataMagic.import_csv(geo_data, options)
    end
    after(:all) do
      DataMagic.destroy
      ENV['ALLOW_MISSING_YML'] = ''
    end

    it "#search can find an attribute" do
      sfo_location = { lat: 37.615223, lon: -122.389977 }
      DataMagic.logger.debug "sfo_location[:lat] #{sfo_location[:lat].class} #{sfo_location[:lat].inspect}"
      search_options = { distance: "100mi", zip: "94102" }
      result = DataMagic.search({}, search_options)
      result["results"] = result["results"].sort_by { |k| k["city"] }
      expected["results"] = [
        { "city" => "San Francisco", "location" => { "lat" => 37.727239, "lon" => -123.032229 } },
        { "city" => "San Jose",      "location" => { "lat" => 37.296867, "lon" => -121.819306 } }
      ]
      expected['metadata']["total"] = expected["results"].length
      expect(result).to eq(expected)
    end

    it "#search with a fields filter can return location.lat and location.lon values" do
      sf_location = { lat: 37.727239, lon: -123.032229 }
      DataMagic.logger.debug "sfo_location[:lat] #{sf_location[:lat].class} #{sf_location[:lat].inspect}"
      response = DataMagic.search({city: "San Francisco"}, {:fields => ["location.lat", "location.lon"]})
      result = response["results"][0]
      expect(result.keys.length).to eq(2)
      expect(result).to include("location.lat")
      expect(result).to include("location.lat")
      expect(result["location.lat"]).to eq sf_location[:lat]
      expect(result["location.lon"]).to eq sf_location[:lon]
    end
  end

  describe "with sample-data" do
    before do
      ENV['DATA_PATH'] = './sample-data'
      DataMagic.init(load_now: true)
    end
    after do
      DataMagic.destroy
    end

    it "can sort" do
      response = DataMagic.search({}, sort: "population:asc")
      expect(response["results"][0]['name']).to eq("Rochester")
    end

    it "can match a field on several given integer values" do
      response = DataMagic.search({population: "8175133,3792621,2695598,"}, sort: "population:desc")
      expect(response["results"].length).to eq(3)
      expect(response["results"][0]['name']).to eq("New York")
      expect(response["results"][1]['name']).to eq("Los Angeles")
      expect(response["results"][2]['name']).to eq("Chicago")
    end
  end

  describe "with null fields in the data" do
    before :example do
      ENV['DATA_PATH'] = './spec/fixtures/nested_files'
      DataMagic.init(load_now: true)
    end

    after :example do
      DataMagic.destroy
    end

    context "with a fields filter containing NULL fields" do
      it "should include the NULL fields" do
        response = DataMagic.search({id: "11"}, {:fields => ["name", "state"]})
        result = response["results"][0]
        expect(result.keys.length).to eq(2)
        expect(result).to include("state")
        expect(result["state"]).to be_nil
      end

      it "should include nested NULL fields" do
        response = DataMagic.search({id: "11"}, {:fields => ["2012.sat_average"]})
        result = response["results"][0]
        expect(result.keys.length).to eq(1)
        expect(result).to include("2012.sat_average")
        expect(result["2012.sat_average"]).to be_nil
      end
    end

    context "without a fields filter" do
      it "should include NULL fields" do
        response = DataMagic.search({id: "11"})
        result = response["results"][0]
        expect(result).to include("state")
        expect(result["2012"]).to include("sat_average")
      end
    end

  end
end
