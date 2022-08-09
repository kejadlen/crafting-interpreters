require_relative "../test_helper"

require "lox/interpreter"
require "lox/parser"
require "lox/scanner"

class TestInterpreter < Lox::Test
  def setup
    @scanner = Lox::Scanner.new
    @interpreter = Lox::Interpreter.new
  end

  # def test_literal
  #   assert_evaluated(42.0, "42")
  # end

  def test_grouping
    assert_evaluated "42", "(42)"
  end

  def test_unary
    assert_evaluated "-42", "-42"
    assert_evaluated "false", "!42"
    assert_evaluated "false", "!true"
    assert_evaluated "true", "!false"
    assert_evaluated "true", "!nil"
  end

  def test_binary
    assert_evaluated "42", "100 - 58"
    assert_evaluated "42", "84 / 2"
    assert_evaluated "42", "21 * 2"

    # precedence
    assert_evaluated "42", "2 * 25 - 8"

    assert_evaluated "42", "40 + 2"
    assert_evaluated "42", "\"4\" + \"2\""

    assert_evaluated "true", "1 > 0"
    assert_evaluated "false", "0 > 0"
    assert_evaluated "false", "0 > 1"

    assert_evaluated "true", "1 >= 0"
    assert_evaluated "true", "0 >= 0"
    assert_evaluated "false", "0 >= 1"

    assert_evaluated "false", "1 < 0"
    assert_evaluated "false", "0 < 0"
    assert_evaluated "true", "0 < 1"

    assert_evaluated "false", "1 <= 0"
    assert_evaluated "true", "0 <= 0"
    assert_evaluated "true", "0 <= 1"

    assert_evaluated "true", "0 != 1"
    assert_evaluated "false", "0 != 0"
    assert_evaluated "false", "nil != nil"
    assert_evaluated "true", "nil != 1"

    assert_evaluated "false", "0 == 1"
    assert_evaluated "true", "0 == 0"
    assert_evaluated "true", "nil == nil"
    assert_evaluated "false", "nil == 1"
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
        assert_evaluated nil, src
      end
    end
  end

  def test_stringify
    assert_evaluated "nil", "nil"
    assert_evaluated "42", "42"
    assert_evaluated "42.1", "42.1"
    assert_evaluated "foo", "\"foo\""
  end

  def test_multiple_statements
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      one
      true
      3
    EXPECTED
      print "one";
      print true;
      print 2 + 1;
    SRC
  end

  private

  def assert_interpreted(expected, src)
    output = with_stdout {
      stmts = Lox::Parser.new(@scanner.scan(src)).parse!
      @interpreter.interpret(stmts)
    }
    assert_equal expected, output
  end

  def assert_evaluated(expected, src)
    assert_interpreted(expected, "print #{src};")
  end

  def with_stdout
    original = $stdout
    $stdout = StringIO.new

    yield

    output = $stdout.string.chomp
    $stdout = original
    output
  end

end
