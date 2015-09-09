require 'spec_helper'
require 'fixtures/data.rb'

shared_examples_for "api request" do
  context "CORS requests" do
    it "sets the Access-Control-Allow-Origin header to allow CORS from anywhere" do
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it "allows GET HTTP method thru CORS" do
      allowed_http_methods = last_response.header['Access-Control-Allow-Methods']
      %w{GET}.each do |method| # don't expect we'll need: POST PUT DELETE
        expect(allowed_http_methods).to include(method)
      end
    end
  end
end


describe 'api', type: 'feature' do
  let(:json_response) { JSON.parse(last_response.body) }
  let(:expected) do
    {
      "metadata" => expected_metadata,
      "results"  => expected_results
    }
  end
  let(:expected_metadata) do
    {
      "total" => 1,
      "page" => 0,
      "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
    }
  end

  context 'with some sample data' do
    before do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/sample-data'
      DataMagic.init(load_now: true)
    end
    after do
      DataMagic.destroy
    end


    it "loads the endpoint list" do
      get "/v1/endpoints"

      expect(last_response).to be_ok
      expect(last_response.content_type).to eq('application/json')
      expected = {
        'endpoints' => [
          'name' => 'cities',
          'url' => '/v1/cities',
        ]
      }
      expect(json_response).to eq expected
    end

    it "raises a 404 on missing endpoints" do
      expected = {
        "error" => 404,
        "message" => "missing not found. Available endpoints: cities",
      }
      get "/v1/missing"
      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq('application/json')
      expect(json_response).to eq(expected)
    end

    it "raises a 400 on a bad query" do
      expected = {
        "errors" => [{
          "error" => "parameter_not_found",
          "input" => "frog",
          "message" => "The input parameter 'frog' is not known in this dataset."
        }, {
          "error" => 'operator_not_found',
          "parameter" => "frog",
          "input" => "blah",
          "message" => "The input operator 'blah' (appended to the parameter 'frog') is not known or supported. (Known operators: range, ne, not)"
        }]
      }
      get "/v1/cities?frog__blah=toad"
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to eq('application/json')
      expect(json_response).to eq(expected)
    end

    describe "data description" do
      before do
        get '/v1/data.json'
      end

      it_behaves_like "api request"

      it "responds with json" do
        expect(last_response).to be_ok
        expect(last_response.content_type).to eq('application/json')
      end
    end

    describe "query" do
      describe "with one term" do
        before do
          get '/v1/cities.json?name=Chicago'
        end
        let(:expected_results) do
          [
            { "state" => "IL", "id"=>"1714000", "code"=>"00428803",
              "name" => "Chicago", "population" => 2695598,
              "area"=> { "land" => 227.635, "water" => 6.479 },
              "location" => { "lat" => 41.837551, "lon" => -87.681844 }
            }
          ]
        end

        it_behaves_like "api request"

        it "responds with json" do
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('application/json')
          expect(json_response).to eq(expected)
        end

      end

      describe "exporting csv" do
        before do
          get '/v1/cities.csv?name=Chicago'
        end

        it_behaves_like "api request"

        it "handles a csv format request" do
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('text/csv;charset=utf-8')

          result = CSV.parse(last_response.body)

          expect(result.length).to eq 2

          expect(result[0]).to eq %w(id code name state population area.land area.water location.lat location.lon)
          expect(result[1]).to eq %w(1714000 00428803 Chicago IL 2695598 227.635 6.479 41.837551 -87.681844)
        end
      end

      describe "with options" do
        let(:expected_results) { [{ "name" => "Boston", "population" => 617594 }] }
        it "can return a subset of fields" do
          get '/v1/cities?state=MA&_fields=name,population'
          expect(last_response).to be_ok
          expect(json_response).to eq(expected)
        end
      end

      describe "with float" do
        before do
          get '/v1/cities?area.land=302.643'
        end
        let(:expected_results) do
          [ { "area"=> { "land" => 302.643, "water" => 165.841 },
              "code"=>"02395220", "name"=>"New York",
              "location" => { "lat" => 40.664274, "lon" => -73.9385 },
              "state"=>"NY", "id"=>"3651000", "population"=>8175133 } ]
        end

        it "responds with json" do
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('application/json')
          expect(json_response).to eq(expected)
        end
      end

      describe "near zipcode" do
        before do
          get '/v1/cities?_zip=94132&_distance=30mi'
        end
        let(:expected_results) do
          [{"state"=>"CA", "id"=>"0653000", "code"=>"02411292", "name"=>"Oakland",
            "population"=>390724, "area"=>{"land"=>55.786,"water"=>22.216},
            "location"=>{"lat"=>37.769857, "lon"=>-122.22564}} ]
        end

        it "can find an attribute from an imported file" do
          expect(last_response).to be_ok
          json_response["results"] = json_response["results"].sort_by { |k| k["name"] }
          expect(json_response).to eq(expected)
        end
      end

      # @todo add example with multi words
      describe "with sort" do
        it 'returns the data sorted by population in ascending order' do
          get '/v1/cities?_sort=population:asc'
          expect(last_response).to be_ok
          expect(json_response["results"][0]['name']).to eq("Rochester")
        end

        it 'returns the data sorted by name in ascending order' do
          get '/v1/cities?_sort=name'
          expect(last_response).to be_ok
          csv_path = File.expand_path "../../sample-data/cities100.csv", __dir__
          data = CSV.read(csv_path).slice(1..-1)
          data = data.map { |row| row[3] }.sort.slice(0,20)
          expect(json_response["results"].map { |r| r['name'] }).to eq(data)
        end

        context 'when :sort is "name"' do
          it 'returns the data sorted by name in descending order' do
            get '/v1/cities?_sort=name:desc&_per_page=100'
            expect(last_response).to be_ok
            expect(json_response["results"][0]['name']).to eq("Winston-Salem")
            expect(json_response["results"][-1]['name']).to eq("Albuquerque")
          end
        end
      end

      describe "with pagination" do
        it "can specify both page and page size" do
          get '/v1/cities?_page=1&_per_page=3'
          expect(last_response).to be_ok
          expect(json_response['metadata']["per_page"].to_i).to eq(3)
          expect(json_response['metadata']["page"].to_i).to eq(1)
          expect(json_response["results"].length).to eq(3)
        end

        it "can use a default page size" do
          get '/v1/cities?_page=1'
          expect(last_response).to be_ok
          expect(json_response['metadata']["per_page"].to_i).to eq(DataMagic::DEFAULT_PAGE_SIZE)
          expect(json_response['metadata']["page"].to_i).to eq(1)
          expect(json_response["results"].length).to eq(DataMagic::DEFAULT_PAGE_SIZE)
        end
      end
    end

  end

  context "with nested data" do
    before do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/nested_files'
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
    end
    after do
      DataMagic.destroy
    end
    let(:expected_results) do
      [ { "id" => "9", "city" => "Tanner", "state" => "AL",
          "name" => "Inquisitive Farm College",
          "2013" => { "earnings" =>
                        { "6_yrs_after_entry" =>
                            { "percent_gt_25k" => 0.19, "median" => 34183 } },
                      "sat_average" => "971" },
          "2012" => { "earnings" =>
                        { "6_yrs_after_entry" =>
                            { "percent_gt_25k" => 0.83, "median" => 42150 } },
                      "sat_average" => "1292" } }]
    end
    it "can search" do
      get '/v1/school?name=Inquisitive Farm College'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end
    it "can search for nested number" do
      get '/v1/school?2013.earnings.6_yrs_after_entry.median=34183'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for nested float" do
      get '/v1/school?2013.earnings.6_yrs_after_entry.percent_gt_25k=0.19'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    describe "when searching for range" do
      let(:expected_results) do
        [ { "id" => "8", "city" => "Birmingham", "state" => "AL",
            "name" => "Condemned Balloon Institute",
            "2013" => { "earnings" =>
                          { "6_yrs_after_entry" =>
                              { "percent_gt_25k" => 0.59, "median" => 59759 } },
                        "sat_average" => "616" },
            "2012" => { "earnings" =>
                          { "6_yrs_after_entry" =>
                              { "percent_gt_25k" => 0.97, "median" => 30063 } },
                        "sat_average" => "1420" } }]
      end
      it "can search for range" do
        get '/v1/school?2013.earnings.6_yrs_after_entry.median__range=49310..'
        expect(last_response).to be_ok
        expect(json_response).to eq(expected)
      end
    end
  end

  context "with alternate nested data" do
    before do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/nested2'
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
    end

    after do
      DataMagic.destroy
    end

    let(:expected_results) do
      [{ "id" => 9, "school" => {
           "city" => "Tanner", "state" => "AL",
           "zip" => 35671, "name" => "Inquisitive Farm College" }
      }]
    end

    it "can search for nested name" do
      get '/v1/fakeschool?school.name=Inquisitive Farm College'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for nested number" do
      get '/v1/fakeschool?school.zip=35671'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    describe "when searching for range" do
      let(:expected_results) do
        [ { "id" => 7,
          "school" => { "city" => "Auburn University",
                        "state" => "AL", "zip" => 36849,
                        "name" => "Alabama Beauty College of Auburn University" }
        } ]
      end
      it "can search for range" do
        get '/v1/fakeschool?school.zip__range=36800..'
        expect(last_response).to be_ok
        expect(json_response).to eq(expected)
      end
    end
  end

  describe "deprecated option syntax" do
    before do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/sample-data'
      DataMagic.init(load_now: true)
    end
    after do
      DataMagic.destroy
    end

    # TODO: This should fail once the old non-prefixed option syntax
    #       is turned off
    it "still works" do
      get '/v1/cities?zip=94132&distance=30mi'
      expected_results = [
        {"area"=>{"land"=>55.786, "water"=>22.216}, "code"=>"02411292", "name"=>"Oakland", 
          "location"=>{"lon"=>-122.22564, "lat"=>37.769857}, "state"=>"CA", "id"=>"0653000", 
          "population"=>390724}      ]
      expect(last_response).to be_ok
      json_response["results"] = json_response["results"].sort_by { |k| k["name"] }
      expect(json_response["results"]).to eq(expected_results)
    end

    # TODO: ... and vice versa
    xit "no longer works" do
      expected = {
        "errors" => [{
          "error" => 'parameter_not_found',
          "message" => "The input parameter 'zip' is not known in this dataset.",
          "input" => 'zip'
        }, {
          "error" => 'parameter_not_found',
          "message" => "The input parameter 'distance' is not known in this dataset.",
          "input" => 'distance'
        }]
      }
      get '/v1/cities?zip=94132&distance=30mi'
      expect(last_response.status).to eq(400)
      expect(last_response.content_type).to eq('application/json')
      expect(json_response).to eq(expected)
    end
  end
end
