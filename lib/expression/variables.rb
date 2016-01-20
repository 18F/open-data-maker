require 'parslet'

class Expression
  class Variables < Parslet::Transform
    rule(:var => simple(:var)) {
      [String(var)]
    }
    rule(:or => { :left => subtree(:left), :right => subtree(:right) }) do
      (left + right)
    end

    rule(:and => { :left => subtree(:left), :right => subtree(:right) }) do
      (left + right)
    end

  end
end
