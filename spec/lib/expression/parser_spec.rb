require 'expression/parser'

describe Expression::Parser do

  let(:parser) { Expression::Parser.new }
  describe 'vars' do
    it "parses one" do
      expect(parser.parse('one')).to eq(var: 'one')
    end
    it "preserves case " do
      expect(parser.parse('ONe')).to eq(var: 'ONe')
    end
    it "consumes trailing white space" do
      expect(parser.parse('one    ')).to eq(var: 'one')
    end
  end

  it "parses or expression" do
    expect(parser.parse('apples or oranges')).to eq(
      {or: {left: {var: "apples"}, right: {var: "oranges"}}}
    )
  end

  it "parses and expression" do
    expect(parser.parse('apples and oranges')).to eq(
      {and: {left: {var: "apples"}, right: {var: "oranges"}}}
    )
  end

  describe "parens" do
    it "nested 'or'" do
      expect(parser.parse('(apples or cranberries) and nuts')).to eq(
        {:and => {
          :left=>{:or=>{:left=>{:var=>"apples"}, :right=>{:var=>"cranberries"}}},
          :right=>{:var=>"nuts"}}}
      )
    end
    it "nested 'and'" do
      expect(parser.parse('(nuts and cranberries) or apples')).to eq(
        { or: {
          left: { and: { left: {var: "nuts"}, right: {var:"cranberries"}}},
          right: { var: "apples" }
          }
        }
      )
    end

  end

end
