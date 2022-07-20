require_relative "../test_helper"

require "lox/ast_printer"
require "lox/expr"
require "lox/token"

class TestAstPrinter < Lox::Test
  def test_ast_printer
    expr = Lox::Expr::Binary.new(
      Lox::Expr::Unary.new(
        Lox::Token.new(:MINUS, ?-, nil, 1),
        Lox::Expr::Literal.new(123),
      ),
      Lox::Token.new(:STAR, ?*, nil, 1),
      Lox::Expr::Grouping.new(
        Lox::Expr::Literal.new(45.67),
      ),
    )

    assert_equal "(* (- 123) (group 45.67))", Lox::AstPrinter.new.print(expr)
  end
end
