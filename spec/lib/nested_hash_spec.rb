require 'nested_hash'

describe NestedHash do
  let(:input) { {"loc.x" => 1, "loc.y" => 2, "foo.a" => 10, "foo.b" => 20, "loc.z" => 3}}
  let(:expected) {{"loc" => {"x" => 1, "y" => 2, "z" => 3}, "foo" => {"a" => 10, "b" => 20}}}

  let(:symbol_keys) { {x:1, y:2}}
  let(:symbol_keys_result) { {'x' => 1, 'y' => 2}}

  it "creates nested hash elements for string keys with '.'" do
    result = NestedHash.new.add(input)
    expect(result).to eq(expected)
  end

  it "turns symbol keys into simple strings" do
    result = NestedHash.new.add(symbol_keys)
    expect(result).to eq(symbol_keys_result)
  end

  context "deeply nested" do
    let(:input) { {"info.loc.x" => 0.11, "info.loc.y" => 0.222, "foo.a" => 10, "foo.b" => 20}}
    let(:expected) { {"info" => {"loc" => {"x" => 0.11, "y" => 0.222}}, "foo" => {"a" => 10, "b" => 20}}}

    it "creates nested hash elements for string keys with '.'" do
      result = NestedHash.new.add(input)
      expect(result).to eq(expected)
    end

  end

end
