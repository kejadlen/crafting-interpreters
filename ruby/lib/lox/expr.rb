require_relative "visitable"

module Lox
  module Expr
    Binary = Struct.new(:left, :op, :right) do
      include Visitable
    end

    Grouping = Struct.new(:expr) do
      include Visitable
    end

    Literal = Struct.new(:value) do
      include Visitable
    end

    Unary = Struct.new(:op, :right) do
      include Visitable
    end

    Variable = Struct.new(:name) do
      include Visitable
    end
  end
end
