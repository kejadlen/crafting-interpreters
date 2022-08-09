require_relative "visitable"

module Lox
  module Stmt
    Block = Struct.new(:stmts) do
      include Visitable
    end

    Expr = Struct.new(:expr) do
      include Visitable
    end

    Print = Struct.new(:expr) do
      include Visitable
    end

    Var = Struct.new(:name, :initializer) do
      include Visitable
    end
  end
end
