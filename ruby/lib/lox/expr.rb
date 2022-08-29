module Lox
  module Expr
    def self.expr(name, *children)
      klass = Struct.new(name.to_s, *children) do
        def accept(visitor)
          klass = self.class.to_s.split("::").last.downcase
          visitor.send("visit_#{klass}", self)
        end
      end
      const_set(name, klass)
    end

    expr :Assign, :name, :value
    expr :Binary, :left, :op, :right
    expr :Call, :callee, :paren, :args
    expr :Get, :object, :name
    expr :Grouping, :expr
    expr :Literal, :value
    expr :Logical, :left, :op, :right
    expr :Set, :object, :name, :value
    expr :This, :keyword
    expr :Unary, :op, :right
    expr :Variable, :name
  end
end
