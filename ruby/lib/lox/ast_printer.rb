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

    def visit_if(stmt)
      exprs = [stmt.cond, stmt.then]
      exprs << stmt.else if stmt.else
      parenthesize("if", *exprs)
    end

    def visit_expr(expr)
      expr.expr.accept(self)
    end

    def visit_call(call)
      parenthesize(call.callee.accept(self), *call.args)
    end

    def visit_return(stmt)
      exprs = stmt.value ? [stmt.value] : []
      parenthesize("return", *exprs)
    end

    def visit_while(stmt)
      parenthesize("while", stmt.cond, stmt.body)
    end

    private

    def parenthesize(name, *exprs)
      "(#{[name, *exprs.map { _1.accept(self) }].join(" ")})"
    end
  end
end
