require 'nested_hash'

describe NestedHash do
  let(:input) { {"loc.x" => 1, "loc.y" => 2, "foo.a" => 10, "foo.b" => 20, "foo.c.baz" => 3,}}
  let(:expected) {{"loc" => {"x" => 1, "y" => 2}, "foo" => {"a" => 10, "b" => 20, "c" => { "baz" => 3}}}}

  let(:symbol_keys) { {x:1, y:2}}
  let(:symbol_keys_result) { {'x' => 1, 'y' => 2}}


  it ".add created nested hash elements for string keys with '.'" do
    result = NestedHash.new.add(input)
    expect(result).to eq(expected)
  end

  it "does no harm when initialized with an already nested hash" do
    expect(NestedHash.new(expected)).to eq(expected)
  end

  context "methods" do
    let (:result) { NestedHash.new(input) }
    it "can initialize with another Hash" do
      expect(result).to eq(expected)
    end

    it "can generate dotkeys" do
      expect(result.dotkeys.sort).to eq(input.keys.sort)
    end

    it "withdotkeys generates keys with '.'" do
      expect(result.withdotkeys).to eq(input)
    end

    it "dotkeys and withdotkeys have same order" do
      expect(result.withdotkeys.keys).to eq(result.dotkeys)
    end
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
