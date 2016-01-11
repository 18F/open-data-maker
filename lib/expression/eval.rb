
class Expression
  class Eval < Parslet::Transform
    rule(:var => simple(:var)) {
      variables[String(var)]
    }

    # in Ruby 0 is 'truthy' but that's not what most people expect
    rule(:or => { :left => subtree(:left), :right => subtree(:right) }) do
      left == 0 ? right : (left or right)
    end

    rule(:and => { :left => subtree(:left), :right => subtree(:right) }) do
      left == 0 ? left : (left and right)
    end
  end
end
