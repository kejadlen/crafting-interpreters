require_relative "../test_helper"

require "lox/ast_printer"
require "lox/parser"
require "lox/scanner"
require "lox/token"

class TestParser < Lox::Test
  def setup
    @ast_printer = Lox::AstPrinter.new
    @scanner = Lox::Scanner.new
    @parser = Lox::Parser.new
  end

  def test_expression
    assert_parsed "(== 4.0 (>= 2.0 1.0))", :expression, "4 == 2 >= 1"
  end

  def test_term
    assert_parsed "(+ 4.0 (/ 2.0 1.0))", :term, "4 + 2 / 1"
  end

  def test_factor
    assert_parsed "(/ 4.0 (- 2.0))", :factor, "4 / -2"
    assert_parsed "(* 4.0 2.0)", :factor, "4 * 2"
    assert_parsed "(- 2.0)", :factor, "-2"
  end

  def test_unary
    assert_parsed "(! 42.0)", :unary, "!42"
    assert_parsed "(- 42.0)", :unary, "-42"
    assert_parsed "42.0", :unary, "42"
  end

  def test_primary
    assert_parsed "false", :primary, "false"
    assert_parsed "true", :primary, "true"
    assert_parsed "nil", :primary, "nil"
    assert_parsed "42.0", :primary, "42"
    assert_parsed "foo", :primary, "\"foo\""
    assert_parsed "(group foo)", :primary, "(\"foo\")"
  end

  def test_errors
    e = assert_raises Lox::ParseError do
      parse("(42", :primary)
    end
    assert_equal "[line 1] Error at end: Expect ')' after expression.", e.message

    e = assert_raises Lox::ParseError do
      parse("foo foo", :primary)
    end
    assert_equal "[line 1] Error at 'foo': Expect expression.", e.message
  end

  private

  def parse(src, name)
    tokens = @scanner.scan(src)
    Lox::Parser::State.new(tokens).send(name)
  end

  def assert_parsed(expected, name, src)
    expr = parse(src, name)
    assert_equal expected, @ast_printer.print(expr)
  end
end
