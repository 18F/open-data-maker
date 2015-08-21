require 'zipcode/zipcode'

describe Zipcode do
  it "gives a location based on zipcode" do
    location = Zipcode.latlon('94132')
    expect(location).to eq(lat: 37.7211, lon: -122.4754)
  end
  it "supports zipcode given as a number" do
    location = Zipcode.latlon(94132)
    expect(location).to eq(lat: 37.7211, lon: -122.4754)
  end
end
