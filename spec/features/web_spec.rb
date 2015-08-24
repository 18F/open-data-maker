require 'spec_helper'

describe 'app', type: 'feature' do
	before do
		DataMagic.init(load_now: true)
	end

	after do
		DataMagic.destroy
	end

  describe "visiting the home page" do
  	before do
		  get '/'
  	end

  	it "succeeds" do
		  expect(last_response).to be_ok
  	end

		it "renders a list of categories" do
		  expect(last_response.body).to include('Browse Data Details by Category')
		  expect(last_response.body).to include('General') #category name
		  expect(last_response.body).to include('general information about the city, including standard identifiers')
		end
	end
end
