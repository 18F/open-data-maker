class Expression
  attr_accessor :name   # purely for reporting Errors
  attr_reader   :variables

  def initialize(expr, name='unknown')
    @variables = parse(expr)
  end

  private
    def parse(expression)
      match = /\s*(\w+)\s+or\s+(\w+)\s*/.match expression
      # logger.debug("parse_expression #{match.inspect}")
      if match.nil? or match[1].nil? or match[2].nil?
        raise ArgumentError,
          "can't interpret #{expression.inspect} for #{name}"
      end
      [match[1], match[2]]
    end

end
