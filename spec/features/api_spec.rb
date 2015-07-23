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


describe 'api' do
	# app starts up in advance of before :all so for now testing only
	# with ./sample-data

	after(:all) do
		Stretchy.delete 'test-city-data'
		#expect(DataMagic.client.indices.get(index: '_all')).to be_empty
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
		describe "with terms" do
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
						{"state"=>"IL", "name"=>"Chicago", "population"=>"2695598",
							"location"=>{"lat"=>41.837551, "lon"=>-87.681844}}						]
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
				#DataMagic.logger.debug "last_response.body: #{last_response.body.inspect}"
				result = JSON.parse(last_response.body)
				result["results"] = result["results"].sort_by { |k| k["name"] }

				expected = {
				  "total" => 2,
				  "page"  => 0,
				  "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
				  "results" => [
						{"state"=>"CA", "name"=>"Fremont", "population"=>"214089", "location"=>{"lat"=>37.494373, "lon"=>-121.941117}},
						{"state"=>"CA", "name"=>"Oakland", "population"=>"390724", "location"=>{"lat"=>37.769857, "lon"=>-122.22564}}					]
				}
				expect(result).to eq(expected)
			end
		end

	end

end
