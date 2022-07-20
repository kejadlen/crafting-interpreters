module Lox
  module Expr
    Binary = Struct.new(:left, :op, :right) do
      def accept(visitor) = visitor.visit_binary(self)
    end

    Grouping = Struct.new(:expr) do
      def accept(visitor) = visitor.visit_grouping(self)
    end

    Literal = Struct.new(:value) do
      def accept(visitor) = visitor.visit_literal(self)
    end

    Unary = Struct.new(:op, :right) do
      def accept(visitor) = visitor.visit_unary(self)
    end
  end
end
