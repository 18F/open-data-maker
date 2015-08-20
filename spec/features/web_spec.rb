require 'spec_helper'

describe 'app', type: 'feature' do
	before do
		DataMagic.init(load_now: true)
	end

	after do
		DataMagic.destroy
	end

	it "should load the home page" do
	  get '/'
	  expect(last_response).to be_ok
	  expect(last_response.body).to include('Data Details')
	  expect(last_response.body).to include('general information about the city, including standard identifiers')
	end
end
