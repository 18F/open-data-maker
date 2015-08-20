require 'spec_helper'

describe 'app', type: 'feature' do
  before do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/sample-data'
    DataMagic.init(load_now: true)
  end

  after do
    DataMagic.destroy
  end

  it "should load the home page" do
    get '/'
    expect(last_response).to be_ok
  end

  it "should display links to endpoints" do
    get '/'
    expect(last_response.body).to include '<a href="/v1/cities">cities</a>'
  end

  it "renders a list of categories" do
    expect(last_response.body).to include('Browse Data Details by Category')
    expect(last_response.body).to include('General') #category name
    expect(last_response.body).to include('general information about the city, including standard identifiers')
  end
end
