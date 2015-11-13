class Expression
  attr_accessor :name # purely for reporting Errors
  attr_reader :variables

  def initialize(expr, _name = 'unknown')
    @variables = parse(expr)
  end

  private

  def parse(expression)
    match = /\s*(\w+)\s+or\s+(\w+)\s*/.match expression
    if match.nil? || match[1].nil? || match[2].nil?
      fail ArgumentError, "can't interpret #{expression.inspect} for #{name}"
    end
    [match[1], match[2]]
  end
end
