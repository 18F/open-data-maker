require 'spec_helper'

describe 'app' do
	it "should load the home page" do
	  get '/' 
	  expect(last_response).to be_ok
	end
end
