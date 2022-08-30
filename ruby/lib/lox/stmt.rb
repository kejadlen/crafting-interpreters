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
    stmt :Class, :name, :superclass, :methods
    stmt :Expr, :expr
    stmt :Function, :name, :params, :body
    stmt :If, :cond, :then, :else
    stmt :Print, :expr
    stmt :Return, :keyword, :value
    stmt :Var, :name, :initializer
    stmt :While, :cond, :body
  end
end
