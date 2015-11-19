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

  describe '#valid' do
    it "returns true if the zipcode is valid" do
      expect(Zipcode.valid? 94132).to eq(true)
    end
    it "returns false if the zipcode is invalid" do
      expect(Zipcode.valid? 00002).to eq(false)
    end
  end
end
