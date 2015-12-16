require_relative 'parser'
require_relative 'eval'
require_relative 'variables'
require 'hashie'

class Expression
  attr_accessor :name   # purely for reporting Errors
  attr_reader   :variables

  def initialize(expr, name = 'unknown')
    @tree = Parser.new.parse(expr)
    @variables = Variables.new.apply(@tree)
  end

  def evaluate(vars)
    Hashie.stringify_keys! vars
    Eval.new.apply(@tree, variables: vars)
  end
end
