require_relative 'expression_parser'
require_relative 'expression_eval'
require 'hashie'

class Expression
  attr_accessor :name   # purely for reporting Errors
  attr_reader   :variables

  def initialize(expr, name = 'unknown')
    @tree = ExpressionParser.new.parse(expr)
    @variables = Variables.new.apply(@tree)
  end

  def evaluate(vars)
    Hashie.stringify_keys! vars
    ExpressionEval.new.apply(@tree, variables: vars)
  end
end
