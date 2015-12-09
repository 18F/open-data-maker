require 'expression'

describe Expression do
  context "simple or expression" do
    it "can find variables" do
      expr = "ONE or TWO"
      expect(Expression.new(expr).variables).to eq(%w(ONE TWO))
    end
    it "evaluates: 0 OR 1 to be 1" do
      expr = "f or t"
      values = {f:0, t:1}
      expect(Expression.new(expr).evaluate(values)).to eq(1)
    end
    it "evaluates: 1 OR 0 to be 1" do
      expr = "t or f"
      values = {f:0, t:1}
      expect(Expression.new(expr).evaluate(values)).to eq(1)
    end
    it "evaluates: 0 OR 0 to be 0" do
      expr = "f1 or f2"
      values = {f1:0, f2:0}
      expect(Expression.new(expr).evaluate(values)).to eq(0)
    end
    it "evaluates: 1 OR 1 to be 1" do
      expr = "t1 or t2"
      values = {t1:1, t2:1}
      expect(Expression.new(expr).evaluate(values)).to eq(1)
    end
  end
end
