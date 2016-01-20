require 'expression/parser'
require 'expression/variables'

describe Expression::Variables do

  let(:parser) { Expression::Parser.new }
  let(:variables) { Expression::Variables.new }
  it "gets one variable name" do
    expect(variables.apply(parser.parse('one'))).to eq(['one'])
  end
  it "preserves case " do
    expect(variables.apply(parser.parse('ONe'))).to eq(['ONe'])
  end
  it "multiple variables" do
    expect(variables.apply(parser.parse('fox or cow or goat'))).to eq(%w[fox cow goat])
  end

end
