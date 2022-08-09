require_relative "visitable"

module Lox
  module Stmt
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