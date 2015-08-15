require 'spec_helper'
require 'fixtures/data.rb'

shared_examples_for "api request" do
	context "CORS requests" do
		it "sets the Access-Control-Allow-Origin header to allow CORS from anywhere" do
			expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
		end

		it "allows GET HTTP method thru CORS" do
			allowed_http_methods = last_response.header['Access-Control-Allow-Methods']
			%w{GET}.each do |method|  # don't expect we'll need: POST PUT DELETE
				expect(allowed_http_methods).to include(method)
			end
		end
	end
end


describe 'api', type: 'feature' do
	context 'with sample data' do
		# app starts up in advance of before :all so for now testing only
		# with ./sample-data

		after(:all) do
			Stretchy.delete 'test-city-data'
			#expect(DataMagic.client.indices.get(index: '_all')).to be_empty
		end

	  it "loads the endpoint list" do
	    get "/endpoints"

	    expect(last_response).to be_ok
	    expect(last_response.content_type).to eq('application/json')

	    result = JSON.parse(last_response.body)
	    expected = {
	      'endpoints'=>[
	        'name'=>'cities',
	        'url'=>'/cities',
	      ]
	    }
	    expect(result).to eq expected
	  end

	  it "raises a 404 on missing endpoints" do
	    get "/missing"
	    expect(last_response.status).to eq(404)
	    expect(last_response.content_type).to eq('application/json')

	    result = JSON.parse(last_response.body)
	    expected = {
	      "error"=>404,
	      "message"=>"missing not found. Available endpoints: cities",
	    }
	    expect(result).to eq(expected)
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
					get '/cities?name=Chicago'
				end

				it_behaves_like "api request"

				it "responds with json" do
				  expect(last_response).to be_ok
					expect(last_response.content_type).to eq('application/json')

					result = JSON.parse(last_response.body)

					expected = {
						"total" => 1,
					  "page"  => 0,
					  "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
					  "results" => [
							{"state"=>"IL", "name"=>"Chicago", "population"=>2695598,
							 "land_area"=>227.635,   # later we'll make this a float
							 "location"=>{"lat"=>41.837551, "lon"=>-87.681844}}						]
					}
					expect(result).to eq(expected)

				end
			end
			describe "with options" do
				it "can return a subset of fields" do
					get '/cities?state=MA&fields=name,population'

					expect(last_response).to be_ok
					result = JSON.parse(last_response.body)

					expected = {
						"total" => 1,
						"page"  => 0,
						"per_page" => DataMagic::DEFAULT_PAGE_SIZE,
						"results" => [{"name"=>"Boston", "population"=>617594}]
					}
					expect(result).to eq(expected)

				end

			end

			describe "with float" do
				before do
					get '/cities?land_area=302.643'
				end

				it "responds with json" do
				  expect(last_response).to be_ok
					expect(last_response.content_type).to eq('application/json')

					result = JSON.parse(last_response.body)

					expected = {
						"total" => 1,
					  "page"  => 0,
					  "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
					  "results" => [{"state"=>"NY", "name"=>"New York",
							"population"=>8175133, "land_area"=>302.643,
							"location"=>{"lat"=>40.664274, "lon"=>-73.9385}}]
						}
					expect(result).to eq(expected)

				end

			end
			describe "near zipcode" do
				before do
					get '/cities?zip=94132&distance=30mi'
					# why isn't SF, 30 miles from SFO... maybe origin point is not
					# where I expect
				end

				it "can find an attribute from an imported file" do
					expect(last_response).to be_ok
					result = JSON.parse(last_response.body)
					result["results"] = result["results"].sort_by { |k| k["name"] }

					expected = {
					  "total" => 2,
					  "page"  => 0,
					  "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
					  "results" => [
							{"state"=>"CA", "name"=>"Fremont", "population"=>214089, "land_area"=>77.459, "location"=>{"lat"=>37.494373, "lon"=>-121.941117}},
							{"state"=>"CA", "name"=>"Oakland", "population"=>390724, "land_area"=>55.786, "location"=>{"lat"=>37.769857, "lon"=>-122.22564}}]
					}
					expect(result).to eq(expected)
				end
			end

			describe "with sort" do
				it "can sort numbers ascending" do
					get '/cities?sort=population:asc'
					expect(last_response).to be_ok
					response = JSON.parse(last_response.body)
					expect(response["results"][0]['name']).to eq("Rochester")

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

		it "can search" do
			get '/school?name=Inquisitive Farm'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expect(result["total"]).to eq(1)
			first = result["results"].first
			expect(first["name"]).to eq("Inquisitive Farm College")
		end
		it "can search for nested number" do
			get '/school?2013.earnings.median=26318'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expect(result["total"]).to eq(1)
			first = result["results"].first
			expect(first['2013']['earnings']).to eq({"percent_gt_25k"=>0.53, "median"=>26318})
		end

		it "can search for range" do
			get '/school?2013.earnings.median__range=49310..'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expected = {
					"total" => 1,
					"page"  => 0,
					"per_page" => DataMagic::DEFAULT_PAGE_SIZE,
					"results" => [{"id"=>"8", "city"=>"Birmingham", "state"=>"AL",
						"name"=>"Condemned Balloon Institute",
						"2013"=>{"earnings"=>{"percent_gt_25k"=>0.59, "median"=>59759}, 
									   "sat_average"=>"616"},
						"2012"=>{"earnings"=>{"percent_gt_25k"=>0.97, "median"=>30063},
						         "sat_average"=>"1420"}}]
			}
			expect(result).to eq(expected)
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
				"page"  => 0,
				"per_page" => DataMagic::DEFAULT_PAGE_SIZE,
				"results" => [{"id"=>9, "school"=>{"city"=>"Tanner", "state"=>"AL", "zip"=>35671, "name"=>"Inquisitive Farm College"}}]
				}
		}
		it "can search for nested name" do
			get '/fakeschool?school.name=Inquisitive Farm'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expect(result).to eq(expected)
		end
		it "can search for nested number" do
			get '/fakeschool?school.zip=35671'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expect(result).to eq(expected)
		end
		it "can search for range" do
			get '/fakeschool?school.zip__range=36800..'
			expect(last_response).to be_ok
			result = JSON.parse(last_response.body)
			expected["results"] = [
				{"id"=>7,
				 "school"=>{"city"=>"Auburn University",
					 	 "state"=>"AL", "zip"=>36849,
						 "name"=>"Alabama Beauty College of Auburn University"}
				 }
			]
			expect(result).to eq(expected)
		end
	end

end
