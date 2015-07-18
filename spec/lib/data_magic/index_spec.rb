require 'spec_helper'
require 'data_magic'

describe DataMagic::Index do
  context "#delete" do
    it "deletes an index with env scope" do
      index_name = 'myindex'
      scoped_name = DataMagic.scoped_index_name('myindex')
      DataMagic.client.indices.create index: scoped_name
      DataMagic::Index.delete('myindex')
      expect(DataMagic.client.indices.exists? index:scoped_name).to be false
    end
  end  # delete

end
