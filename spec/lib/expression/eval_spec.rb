require 'expression/parser'
require 'expression/eval'

describe Expression::Eval do

  let(:parser) { Expression::Parser.new }
  let(:eval) { Expression::Eval.new }
  let(:values) {{ 'f' => 0, 't' => 1 }}

  it "simple 'or'" do
    expect(
      eval.apply(parser.parse('t or f'), variables: values)
    ).to eq(1)
  end

  describe "simple 'and'" do
    it "true and false" do
      expect(
        eval.apply(parser.parse('t and f'), variables: values)
      ).to eq(0)
    end

    it "false and true" do
      expect(
        eval.apply(parser.parse('f and t'), variables: values)
      ).to eq(0)
    end
  end

  it "mutliple operands" do
    expect(
      eval.apply(parser.parse('f or f or t'), variables: values)
    ).to eq(1)
  end

  describe "parens" do
    it "nested 'or'" do
      expect(
        eval.apply(parser.parse('(f or t) and t'), variables: values)
      ).to eq(1)
    end

    it "nested 'and'" do
      expect(
        eval.apply(parser.parse('(f and t) or f'), variables: values)
      ).to eq(0)
    end
  end
end
