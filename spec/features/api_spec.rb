require 'spec_helper'

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

	it "query should respond with json" do
	  get '/cities?name=Chicago'
	  expect(last_response).to be_ok
		expect(last_response.content_type).to eq('application/json')
	end
end
