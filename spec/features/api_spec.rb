require 'spec_helper'

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
	before(:all) do
		dir_path = './spec/fixtures/import_all'
		@csv_files = Dir.glob("#{dir_path}/**/*.csv")
													.select { |entry| File.file? entry }
		DataMagic.import_all(dir_path)
	end
	after(:all) do
		DataMagic.delete_index('city-data')
	end

	describe "query" do
		before do
			get '/cities?name=Chicago'
		end
		it_behaves_like "api request"
		it "responds with json" do
		  expect(last_response).to be_ok
			expect(last_response.content_type).to eq('application/json')
		end
	end

end
