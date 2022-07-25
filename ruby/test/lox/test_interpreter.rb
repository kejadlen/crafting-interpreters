require_relative "../test_helper"

require "lox/interpreter"
require "lox/parser"
require "lox/scanner"

class TestInterpreter < Lox::Test
  def setup
    @scanner = Lox::Scanner.new
    @parser = Lox::Parser.new
    @interpreter = Lox::Interpreter.new
  end

  def test_literal
    assert_interpreted(42.0, "42")
  end

  def test_grouping
    assert_interpreted(42.0, "(42)")
  end

  def test_unary
    assert_interpreted(-42.0, "-42")
    assert_interpreted(false, "!42")
    assert_interpreted(false, "!true")
    assert_interpreted(true, "!false")
    assert_interpreted(true, "!nil")
  end

  def test_binary
    assert_interpreted(42.0, "100 - 58")
    assert_interpreted(42.0, "84 / 2")
    assert_interpreted(42.0, "21 * 2")

    # precedence
    assert_interpreted(42.0, "2 * 25 - 8")

    assert_interpreted(42.0, "40 + 2")
    assert_interpreted("42", "\"4\" + \"2\"")

    assert_interpreted(true, "1 > 0")
    assert_interpreted(false, "0 > 0")
    assert_interpreted(false, "0 > 1")

    assert_interpreted(true, "1 >= 0")
    assert_interpreted(true, "0 >= 0")
    assert_interpreted(false, "0 >= 1")

    assert_interpreted(false, "1 < 0")
    assert_interpreted(false, "0 < 0")
    assert_interpreted(true, "0 < 1")

    assert_interpreted(false, "1 <= 0")
    assert_interpreted(true, "0 <= 0")
    assert_interpreted(true, "0 <= 1")

    assert_interpreted(true, "0 != 1")
    assert_interpreted(false, "0 != 0")
    assert_interpreted(false, "nil != nil")
    assert_interpreted(true, "nil != 1")

    assert_interpreted(false, "0 == 1")
    assert_interpreted(true, "0 == 0")
    assert_interpreted(true, "nil == nil")
    assert_interpreted(false, "nil == 1")
  end

  def test_errors
    [
      "-true",
      "12 > true",
      "true < 23",
      "false * 23",
      "false + 23",
    ].each do |src|
      assert_raises Lox::RuntimeError do
        evaluate(src)
      end
    end
  end

  def test_stringify
    assert_equal "nil", interpret("nil")
    assert_equal "42", interpret("42")
    assert_equal "42.1", interpret("42.1")
    assert_equal "foo", interpret("\"foo\"")
  end

  private

  def evaluate(src)
    expr = @parser.parse(@scanner.scan(src))
    @interpreter.evaluate(expr)
  end

  def interpret(src)
    expr = @parser.parse(@scanner.scan(src))
    @interpreter.interpret(expr)
  end

  def assert_interpreted(expected, src)
    assert_equal expected, evaluate(src)
  end
end
