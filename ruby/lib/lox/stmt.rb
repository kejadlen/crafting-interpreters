require_relative "expr"

module Lox
  module Stmt
    def self.stmt(name, *children)
      klass = Struct.new(name.to_s, *children) do
        def accept(visitor)
          klass = self.class.to_s.split("::").last.downcase
          visitor.send("visit_#{klass}", self)
        end
      end
      const_set(name, klass)
    end

    stmt :Block, :stmts
    stmt :Fun, :name, :params, :body
    stmt :Expr, :expr
    stmt :If, :cond, :then, :else
    stmt :Print, :expr
    stmt :Var, :name, :initializer
    stmt :While, :cond, :body
  end
end
