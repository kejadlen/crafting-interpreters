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

  def test_environment
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      3
    EXPECTED
      var a = 1;
      var b = 2;
      print a + b;
    SRC
  end

  def test_assignment
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      2
    EXPECTED
      var a = 1;
      print a = 2;
    SRC
  end

  def test_block
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      inner a
      outer b
      global c
      outer a
      outer b
      global c
      global a
      global b
      global c
    EXPECTED
      var a = "global a";
      var b = "global b";
      var c = "global c";
      {
        var a = "outer a";
        var b = "outer b";
        {
          var a = "inner a";
          print a;
          print b;
          print c;
        }
        print a;
        print b;
        print c;
      }
      print a;
      print b;
      print c;
    SRC
  end

  def test_uninitialized_vars_are_nil
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      nil
    EXPECTED
      var a;
      print a;
    SRC
  end

  def test_if
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      true
      false
    EXPECTED
      if (true)
        print "true";
      else
        print "false";

      if (false)
        print "true";
      else
        print "false";
    SRC
  end

  def test_logical
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      hi
      yes
    EXPECTED
      print "hi" or 2; // "hi".
      print nil or "yes"; // "yes".
    SRC
  end

  def test_while
    assert_interpreted <<~EXPECTED.chomp, <<~SRC
      0
      1
      2
    EXPECTED
      var a = 0;
      while (a < 3) {
        print a;
        a = a + 1;
      }
    SRC
  end

  private

  def assert_interpreted(expected, src)
    output = interpret(src)
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

  def interpret(src)
    with_stdout {
      stmts = Lox::Parser.new(@scanner.scan(src)).parse!
      @interpreter.interpret(stmts)
    }
  end

end
