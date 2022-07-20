require "lox"
include Lox

require "open3"

require "minitest/autorun"
require "mocktail"
require "pry"

class TestLox < Minitest::Test
  def test_error_on_more_than_one_arg
    lox_path = File.expand_path("../bin/lox", __dir__)
    o, s = Open3.capture2(lox_path, "foo", "bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: #{lox_path} [script]\n", o
  end
end

class TestRunner < Minitest::Test
  include Mocktail::DSL

  def teardown
    Mocktail.reset
  end

  def test_returns_tokens
    scanner = Mocktail.of(Scanner)
    runner = Runner.new(scanner:)
    stubs { scanner.scan("src") }.with { %w[ some tokens ] }

    tokens = runner.run("src")

    assert_equal %w[ some tokens ], tokens
  end
end

class TestScanner < Minitest::Test
  def setup
    @scanner = Scanner.new
  end

  def test_basic_tokens
    %w[( LEFT_PAREN
       ) RIGHT_PAREN
       { LEFT_BRACE
       } RIGHT_BRACE
       , COMMA
       . DOT
       - MINUS
       + PLUS
       ; SEMICOLON
       * STAR
       != BANG_EQUAL
       ! BANG
       == EQUAL_EQUAL
       = EQUAL
       <= LESS_EQUAL
       < LESS
       >= GREATER_EQUAL
       > GREATER
       / SLASH].each_slice(2).to_h.transform_values(&:to_sym).each do |str, token_type|
         assert_equal token_type.to_sym, @scanner.scan(str)[0].type
       end
  end

  def test_comments_and_whitespace
    tokens = @scanner.scan(<<~SRC)
      (\t) // here lies a comment
      . //
    SRC

    assert_equal %i[LEFT_PAREN RIGHT_PAREN DOT EOF], tokens.map(&:type)
  end

  def test_line_numbers
    tokens = @scanner.scan(<<~SRC)
      (
      )
    SRC

    assert_equal [1, 2, 3], tokens.map(&:line)
  end

  def test_strings
    assert_equal [
      Token.new(:STRING, '""', "", 1),
      Token.new(:EOF, "", nil, 1),
    ], @scanner.scan('""')

    assert_raises do
      @scanner.scan('"')
    end

    assert_equal [
      Token.new(:STRING, '"foo"', "foo", 1),
      Token.new(:EOF, "", nil, 1),
    ], @scanner.scan('"foo"')

    assert_equal [
      Token.new(:STRING, "\"foo\nbar\"", "foo\nbar", 2),
      Token.new(:EOF, "", nil, 2),
    ], @scanner.scan("\"foo\nbar\"")
  end

  def test_numbers
    assert_equal [
      Token.new(:NUMBER, "123", 123.0, 1),
      Token.new(:NUMBER, "123.4", 123.4, 1),
      Token.new(:EOF, "", nil, 1),
    ], @scanner.scan("123 123.4")
  end

  def test_identifiers
    assert_equal [
      Token.new(:OR, "or", nil, 1),
      Token.new(:IDENTIFIER, "orchid", nil, 1),
      Token.new(:IDENTIFIER, "o", nil, 1),
      Token.new(:EOF, "", nil, 1),
    ], @scanner.scan("or orchid o")
  end

  def test_block_comments
    tokens = @scanner.scan(<<~SRC)
      foo
      /* here lies a /* nested */ block comment
      with newlines */
      bar
    SRC

    assert_equal [
      Token.new(:IDENTIFIER, "foo", nil, 1),
      Token.new(:IDENTIFIER, "bar", nil, 4),
      Token.new(:EOF, "", nil, 5),
    ], tokens

    assert_raises do
      @scanner.scan("/*")
    end
  end
end

class TestAstPrinter < Minitest::Test
  def test_ast_printer
    expr = Expr::Binary.new(
      Expr::Unary.new(
        Token.new(:MINUS, ?-, nil, 1),
        Expr::Literal.new(123),
      ),
      Token.new(:STAR, ?*, nil, 1),
      Expr::Grouping.new(
        Expr::Literal.new(45.67),
      ),
    )

    assert_equal "(* (- 123) (group 45.67))", AstPrinter.new.print(expr)
  end
end
