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
      get "/endpoints"

      expect(last_response).to be_ok
      expect(last_response.content_type).to eq('application/json')
      expected = {
        'endpoints' => [
          'name' => 'cities',
          'url' => '/cities',
        ]
      }
      expect(json_response).to eq expected
    end

    it "raises a 404 on missing endpoints" do
      get "/missing"
      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq('application/json')
      expected = {
        "error" => 404,
        "message" => "missing not found. Available endpoints: cities",
      }
      expect(json_response).to eq(expected)
    end

    describe "data description" do
      before do
        get '/data.json'
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
          get '/cities.json?name=Chicago'
        end

        it_behaves_like "api request"

        it "responds with json" do
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('application/json')
          expected = {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => [
              { "state" => "IL", "name" => "Chicago", "population" => 2695598,
                "land_area" => 227.635, # later we'll make this a float
                "location" => { "lat" => 41.837551, "lon" => -87.681844 } }]
          }
          expect(json_response).to eq(expected)
        end

      end

      describe "exporting csv" do
	  		before do
				get '/cities.csv?name=Chicago'
			end

			it_behaves_like "api request"

			it "handles a csv format request" do
			  expect(last_response).to be_ok
				expect(last_response.content_type).to eq('text/csv;charset=utf-8')

				result = CSV.parse(last_response.body)

				expect(result.length).to eq 2

				expect(result[0]).to eq %w[state name population land_area location.lat location.lon]
				expect(result[1]).to eq %w[IL Chicago 2695598 227.635 41.837551 -87.681844]
			end
		end

      describe "with options" do
        it "can return a subset of fields" do
          get '/cities?state=MA&fields=name,population'
          expect(last_response).to be_ok
          expected = {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => [{ "name" => "Boston", "population" => 617594 }]
          }
          expect(json_response).to eq(expected)
        end
      end

      describe "with float" do
        before do
          get '/cities?land_area=302.643'
        end

        it "responds with json" do
          expect(last_response).to be_ok
          expect(last_response.content_type).to eq('application/json')
          expected = {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => [{ "state" => "NY", "name" => "New York",
                            "population" => 8175133, "land_area" => 302.643,
                            "location" => { "lat" => 40.664274, "lon" => -73.9385 } }]
          }
          expect(json_response).to eq(expected)
        end
      end

      describe "near zipcode" do
        before do
          get '/cities?zip=94132&distance=30mi'
        end

        it "can find an attribute from an imported file" do
          expect(last_response).to be_ok
          json_response["results"] = json_response["results"].sort_by { |k| k["name"] }
          expected = {
            "total" => 1,
            "page"  => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => [
              {"state"=>"CA", "name"=>"Oakland", "population"=>390724, "land_area"=>55.786, "location"=>{"lat"=>37.769857, "lon"=>-122.22564}}]
          }
          expect(json_response).to eq(expected)
        end
      end

      # @todo add example with multi words
      describe "with sort" do
        it 'returns the data sorted by population in ascending order' do
          get '/cities?sort=population:asc'
          expect(last_response).to be_ok
          expect(json_response["results"][0]['name']).to eq("Rochester")
        end

        context 'when :sort is "name"' do
          it 'returns the data sorted by name in descending order' do
            get '/cities?sort=name:desc&per_page=100'
            expect(last_response).to be_ok
            expect(json_response["results"][0]['name']).to eq("Winston-Salem")
            expect(json_response["results"][-1]['name']).to eq("Albuquerque")
          end
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
    let(:expected) {
      {
        "total" => 1,
        "page" => 0,
        "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
        "results" => [{ "id" => "9", "city" => "Tanner", "state" => "AL",
                        "name" => "Inquisitive Farm College",
                        "2013" => { "earnings" =>
                                      { "6_yrs_after_entry" =>
                                          { "percent_gt_25k" => 0.19, "median" => 34183 } },
                                    "sat_average" => "971" },
                        "2012" => { "earnings" =>
                                      { "6_yrs_after_entry" =>
                                          { "percent_gt_25k" => 0.83, "median" => 42150 } },
                                    "sat_average" => "1292" } }]
      }
    }
    it "can search" do
      get '/school?name=Inquisitive Farm College'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end
    it "can search for nested number" do
      get '/school?2013.earnings.6_yrs_after_entry.median=34183'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for nested float" do
      get '/school?2013.earnings.6_yrs_after_entry.percent_gt_25k=0.19'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for range" do
      get '/school?2013.earnings.6_yrs_after_entry.median__range=49310..'
      expect(last_response).to be_ok
      expected["results"] = [
        { "id" => "8", "city" => "Birmingham", "state" => "AL",
          "name" => "Condemned Balloon Institute",
          "2013" => { "earnings" =>
                        { "6_yrs_after_entry" =>
                            { "percent_gt_25k" => 0.59, "median" => 59759 } },
                      "sat_average" => "616" },
          "2012" => { "earnings" =>
                        { "6_yrs_after_entry" =>
                            { "percent_gt_25k" => 0.97, "median" => 30063 } },
                      "sat_average" => "1420" } }]
      expect(json_response).to eq(expected)
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

    let(:expected) {
      {
        "total" => 1,
        "page" => 0,
        "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
        "results" => [{ "id" => 9, "school" => { "city" => "Tanner", "state" => "AL", "zip" => 35671, "name" => "Inquisitive Farm College" } }]
      }
    }

    it "can search for nested name" do
      get '/fakeschool?school.name=Inquisitive Farm College'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for nested number" do
      get '/fakeschool?school.zip=35671'
      expect(last_response).to be_ok
      expect(json_response).to eq(expected)
    end

    it "can search for range" do
      get '/fakeschool?school.zip__range=36800..'
      expect(last_response).to be_ok
      expected["results"] = [
        { "id" => 7,
          "school" => { "city" => "Auburn University",
                        "state" => "AL", "zip" => 36849,
                        "name" => "Alabama Beauty College of Auburn University" }
        }
      ]
      expect(json_response).to eq(expected)
    end
  end
end
