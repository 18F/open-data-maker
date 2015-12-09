class Expression
  class Eval < Parslet::Transform
    rule(:var => simple(:var)) {
      variables[String(var)]
    }

    rule(:or => { :left => subtree(:left), :right => subtree(:right) }) do
      (left == 0 || left == 0.0 ? right : (left or right))
    end

    rule(:and => { :left => subtree(:left), :right => subtree(:right) }) do
      (left and right)
    end
  end
end
