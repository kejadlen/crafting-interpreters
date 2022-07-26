module Lox
  module Expr
    module Visitable
      def accept(visitor)
        klass = self.class.to_s.split("::").last.downcase
        visitor.send("visit_#{klass}", self)
      end
    end

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
  end
end
