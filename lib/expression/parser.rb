require 'parslet'
# based on https://github.com/kschiess/parslet/blob/master/example/boolean_algebra.rb
# usage:
# def parse(str)
#   ExpressionParser.new.parse(str)
#
# rescue Parslet::ParseFailed => failure
#   puts failure.cause.ascii_tree
# end
#
# tree = ExpressionParser.new.parse("one or two")
#  => {:or=>{:left=>{:var=>"one"@0}, :right=>{:var=>"two"@7}}}
# Transformer.new.apply(tree, variables: {"one"=>1, "two"=>2})
#
# Variables.new.apply(tree)

class Expression
  class Parser < Parslet::Parser
  rule(:space)  { match[" "].repeat(1) }
  rule(:space?) { space.maybe }

  rule(:lparen) { str("(") >> space? }
  rule(:rparen) { str(")") >> space? }

  rule(:and_operator) { str("and") >> space? }
  rule(:or_operator)  { str("or")  >> space? }

  rule(:var) { match["[^\s]"].repeat(1).as(:var) >> space? }

  # The primary rule deals with parentheses.
  rule(:primary) { lparen >> or_operation >> rparen | var }

  # Note that following rules are both right-recursive.
  rule(:and_operation) {
    (primary.as(:left) >> and_operator >>
      and_operation.as(:right)).as(:and) |
    primary }

  rule(:or_operation)  {
    (and_operation.as(:left) >> or_operator >>
      or_operation.as(:right)).as(:or) |
    and_operation }

  # We start at the lowest precedence rule.
  root(:or_operation)
end
end
