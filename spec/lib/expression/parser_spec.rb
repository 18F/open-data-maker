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

  describe 'or' do
    it "parses or expression" do
      expect(parser.parse('apples or oranges')).to eq(
        {or: {left: {var: "apples"}, right: {var: "oranges"}}}
      )
    end
  end



end
