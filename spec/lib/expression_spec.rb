require 'expression'

describe Expression do
  context "simple or expression" do
    it "can find two variables" do
      expr = "ONE or TWO"
      expect(Expression.new(expr).variables).to eq(%w(ONE TWO))
    end
    it "can find multiple variables" do
      expr = "ONE or TWO or THREE"
      expect(Expression.new(expr).variables).to eq(%w(ONE TWO))
    end
    it "evaluates: false OR true to be true" do
      expr = "f or t"
      values = {f:0, t:1}
      expect(Expression.new(expr).evaluate(values)).to eq(true)
    end
    it "evaluates: true OR false to be true" do
      expr = "t or f"
      values = {f:0, t:1}
      expect(Expression.new(expr).evaluate(values)).to eq(true)
    end
    it "evaluates: false OR false to be false" do
      expr = "f1 or f2"
      values = {f1:0, f2:0}
      expect(Expression.new(expr).evaluate(values)).to eq(false)
    end
    it "evaluates: true OR true to be true" do
      expr = "t1 or t2"
      values = {t1:0, t2:0}
      expect(Expression.new(expr).evaluate(values)).to eq(true)
    end
  end
end
