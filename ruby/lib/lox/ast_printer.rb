module Lox
  class AstPrinter
    def print(expr) = expr.accept(self)

    def visit_binary(expr)   = parenthesize(expr.op.lexeme, expr.left, expr.right)
    def visit_grouping(expr) = parenthesize("group", expr.expr)
    def visit_literal(expr)  = expr.value&.to_s || "nil"
    def visit_unary(expr)    = parenthesize(expr.op.lexeme, expr.right)

    def visit_print(expr)    = parenthesize("print", expr.expr)

    def visit_var(expr)
      exprs = [expr.initializer].reject(&:nil?)
      parenthesize("var #{expr.name.lexeme}", *exprs)
    end

    def visit_variable(expr)
      "(var #{expr.name.lexeme})"
    end

    def visit_assign(expr)
      parenthesize("assign #{expr.name.lexeme}", expr.value)
    end

    def visit_block(expr)
      parenthesize("block", *expr.stmts)
    end

    private

    def parenthesize(name, *exprs)
      inside = [name]
      inside.concat(exprs.map {|expr| expr.accept(self) })
      "(#{inside.join(" ")})"
    end
  end
end
