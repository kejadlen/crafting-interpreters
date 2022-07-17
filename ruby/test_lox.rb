require "lox"

require "open3"

require "minitest/autorun"
require "mocktail"
require "pry"

class TestLox < Minitest::Test
  def test_error_on_more_than_one_arg
    o, s = Open3.capture2("./lox.rb foo bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: ./lox.rb [script]\n", o
  end
end

class TestRunner < Minitest::Test
  include Mocktail::DSL

  def teardown
    Mocktail.reset
  end

  def test_returns_tokens
    scanner = Mocktail.of(Lox::Scanner)
    runner = Lox::Runner.new(scanner:)
    stubs { scanner.scan("src") }.with { %w[ some tokens ] }

    tokens = runner.run("src")

    assert_equal %w[ some tokens ], tokens
  end
end

class TestScanner < Minitest::Test
  def setup
    @scanner = Lox::Scanner.new
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
         assert_equal [token_type.to_sym], @scanner.scan(str).map(&:type)
       end
  end

  def test_comments_and_whitespace
    tokens = @scanner.scan(<<~SRC)
      (\t) // here lies a comment
      .
    SRC

    assert_equal %i[LEFT_PAREN RIGHT_PAREN DOT], tokens.map(&:type)
  end

  def test_line_numbers
    tokens = @scanner.scan(<<~SRC)
      (
      )
    SRC

    assert_equal [1, 2], tokens.map(&:line)
  end

  def test_strings
    assert_equal [Lox::Token.new(:STRING, '""', "", 1)], @scanner.scan('""')
    assert_equal [], @scanner.scan('"') # TODO test the error once it's exposed
    assert_equal [Lox::Token.new(:STRING, '"foo"', "foo", 1)], @scanner.scan('"foo"')
    assert_equal [Lox::Token.new(:STRING, "\"foo\nbar\"", "foo\nbar", 2)], @scanner.scan("\"foo\nbar\"")
  end

  def test_numbers
    assert_equal [
      Lox::Token.new(:NUMBER, "123", 123.0, 1),
      Lox::Token.new(:NUMBER, "123.4", 123.4, 1),
    ], @scanner.scan("123 123.4")
  end

  def test_identifiers
    assert_equal [
      Lox::Token.new(:OR, "or", nil, 1),
      Lox::Token.new(:IDENTIFIER, "orchid", nil, 1),
    ], @scanner.scan("or orchid")
  end

  def test_block_comments
    tokens = @scanner.scan(<<~SRC)
      foo
      /* here lies a block comment */
      bar
    SRC

    assert_equal [
      Lox::Token.new(:IDENTIFIER, "foo", nil, 1),
      Lox::Token.new(:IDENTIFIER, "bar", nil, 3),
    ], tokens
  end
end
