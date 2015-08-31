require 'expression'

describe Expression do
  context "simple or expression" do
    it "can find variables" do
      expr = "ONE or TWO"
      expect(Expression.new(expr).variables).to eq(%w(ONE TWO))
    end
  end
end
