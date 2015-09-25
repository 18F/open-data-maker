require 'spec_helper'

describe Example do
  let(:hash) do
    { name: 'foo',
      description: 'interesting thing',
      params: 'a=1&b=something',
      endpoint: 'api' }
  end
  subject(:e) { Example.new(hash) }

  it "has a name" do
    expect(e.name).to eq(hash[:name])
  end
  it "has a description" do
    expect(e.description).to eq(hash[:description])
  end
  it "has a params" do
    expect(e.params).to eq(hash[:params])
  end
  it "has an endpoint" do
    expect(e.endpoint).to eq(hash[:endpoint])
  end

  it "has a link" do
    expect(e.link).to eq("/v1/#{e.endpoint}?#{e.params}")
  end
end
