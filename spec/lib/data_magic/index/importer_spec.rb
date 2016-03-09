require 'spec_helper'
require 'data_magic'

describe "DataMagic::Index::Importer" do
  before do
    ENV['DATA_PATH'] = './spec/fixtures/minimal'
    DataMagic.init(load_now: false)
  end
  after do
    DataMagic.destroy
  end

  it "indexes in parallel based on NPROCS" do
    stub_const('ENV', { 'NPROCS' => '2' })

    data_str = <<-eos
a,b
1,2
3,4
eos
    data = StringIO.new(data_str)
    num_rows, fields = DataMagic.import_csv(data)
    expect(num_rows).to be(2)
    expect(fields).to eq(['a', 'b'])
  end
end
