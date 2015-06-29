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
	describe "query" do
		before(:all) do
			dir_path = './spec/fixtures/import_all'
			@csv_files = Dir.glob("#{dir_path}/**/*.csv")
														.select { |entry| File.file? entry }
			DataMagic.import_all(dir_path)
		end
		after(:all) do
			DataMagic.delete_index('city-data')
		end

		describe "with terms" do
			before do
				get '/cities?name=Chicago'
			end
			it_behaves_like "api request"
			it "responds with json" do
			  expect(last_response).to be_ok
				expect(last_response.content_type).to eq('application/json')
			end
		end

		describe "near zipcode" do
			before do
				get '/places?zip=94132&distance=100mi'
			end
			before(:all) do
				dir_path = './spec/fixtures/geo'
				@csv_files = Dir.glob("#{dir_path}/**/*.csv")
															.select { |entry| File.file? entry }
				DataMagic.import_all(dir_path)
			end
			after(:all) do
				DataMagic.delete_index('place-data')
			end

			it "can find an attribute from an imported file" do
				expect(last_response).to be_ok
				puts "last_response.body: #{last_response.body.inspect}"
				result = JSON.parse(last_response.body)
				result = result.sort_by { |k| k["city"] }

				expected = [
					{"city" => "San Francisco", "location"=>{"lat"=>37.727239, "lon"=>-123.032229}},
					{"city"=>"San Jose",        "location"=>{"lat"=>37.296867, "lon"=>-121.819306}}
				]
				expect(result).to eq(expected)
			end
		end

	end

end
