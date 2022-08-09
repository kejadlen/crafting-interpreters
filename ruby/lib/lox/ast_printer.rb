module Lox
  class AstPrinter
    def print(expr) = expr.accept(self)

    def visit_binary(expr)   = parenthesize(expr.op.lexeme, expr.left, expr.right)
    def visit_grouping(expr) = parenthesize("group", expr.expr)
    def visit_literal(expr)  = expr.value&.to_s || "nil"
    def visit_unary(expr)    = parenthesize(expr.op.lexeme, expr.right)

    def visit_print(expr)    = parenthesize("print", expr.expr)
    def visit_var(expr)      = "(var #{expr.name.lexeme} #{expr.initializer.value})"

    private

    def parenthesize(name, *exprs)
      "(#{name} #{exprs.map {|expr| expr.accept(self) }.join(" ")})"
    end
  end
end
