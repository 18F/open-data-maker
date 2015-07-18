require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe DataMagic do
  it "cleans up after itself" do
    DataMagic.init(load_now: true)
    DataMagic.destroy
    DataMagic.logger.info "just destroyed"
    #expect(DataMagic.client.indices.get(index: '_all')).to be_empty
  end

end
