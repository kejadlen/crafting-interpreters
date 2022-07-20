require_relative "../test_helper"

require "lox/scanner"

class TestScanner < Lox::Test
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
      Lox::Token.new(:STRING, '""', "", 1),
      Lox::Token.new(:EOF, "", nil, 1),
    ], @scanner.scan('""')

    assert_raises do
      @scanner.scan('"')
    end

    assert_equal [
      Lox::Token.new(:STRING, '"foo"', "foo", 1),
      Lox::Token.new(:EOF, "", nil, 1),
    ], @scanner.scan('"foo"')

    assert_equal [
      Lox::Token.new(:STRING, "\"foo\nbar\"", "foo\nbar", 2),
      Lox::Token.new(:EOF, "", nil, 2),
    ], @scanner.scan("\"foo\nbar\"")
  end

  def test_numbers
    assert_equal [
      Lox::Token.new(:NUMBER, "123", 123.0, 1),
      Lox::Token.new(:NUMBER, "123.4", 123.4, 1),
      Lox::Token.new(:EOF, "", nil, 1),
    ], @scanner.scan("123 123.4")
  end

  def test_identifiers
    assert_equal [
      Lox::Token.new(:OR, "or", nil, 1),
      Lox::Token.new(:IDENTIFIER, "orchid", nil, 1),
      Lox::Token.new(:IDENTIFIER, "o", nil, 1),
      Lox::Token.new(:EOF, "", nil, 1),
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
      Lox::Token.new(:IDENTIFIER, "foo", nil, 1),
      Lox::Token.new(:IDENTIFIER, "bar", nil, 4),
      Lox::Token.new(:EOF, "", nil, 5),
    ], tokens

    assert_raises do
      @scanner.scan("/*")
    end
  end
end
