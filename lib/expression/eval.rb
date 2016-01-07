
class Expression
  class Eval < Parslet::Transform
    rule(:var => simple(:var)) {
      variables[String(var)]
    }

    # in Ruby 0 is 'truthy' but that's not what most people expect
    rule(:or => { :left => subtree(:left), :right => subtree(:right) }) do
      result = left == 0 ? right : (left or right)
      result.nil? ? 0 : result
    end

    rule(:and => { :left => subtree(:left), :right => subtree(:right) }) do
      result = left == 0 ? left : (left and right)
      result.nil? ? 0 : result
    end
  end
end
