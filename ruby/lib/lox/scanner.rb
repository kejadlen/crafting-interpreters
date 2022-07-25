require "strscan"

require_relative "error"
require_relative "token"

module Lox
  class Scanner
    TOKENS = %w[
      (  LEFT_PAREN
      )  RIGHT_PAREN
      {  LEFT_BRACE
      }  RIGHT_BRACE
      ,  COMMA
      .  DOT
      -  MINUS
      +  PLUS
      ;  SEMICOLON
      *  STAR
      != BANG_EQUAL
      !  BANG
      == EQUAL_EQUAL
      =  EQUAL
      <= LESS_EQUAL
      <  LESS
      >= GREATER_EQUAL
      >  GREATER
      /  SLASH
    ].each_slice(2).to_h.transform_values(&:to_sym)
    TOKENS_RE = Regexp.union(TOKENS.keys)

    KEYWORDS = %w[
      and    AND
      class  CLASS
      else   ELSE
      false  FALSE
      for    FOR
      fun    FUN
      if     IF
      nil    NIL
      or     OR
      print  PRINT
      return RETURN
      super  SUPER
      this   THIS
      true   TRUE
      var    VAR
      while  WHILE
    ].each_slice(2).to_h.transform_values(&:to_sym)

    class State < Struct.new(:ss, :tokens, :errors, :line)
      def eos? = ss.eos?
      def scan(re) = ss.scan(re)
      def pos = ss.pos

      def initialize(src)
        super(StringScanner.new(src), [], [], 1)
      end

      def add_token(type, text: nil, literal: nil)
        text ||= ss.matched
        self.tokens << Lox::Token.new(type, text, literal, line)
      end
    end

    def scan(src)
      state = State.new(src)

      until state.eos?
        case
        when state.scan(/\/\/(?~\n)/)
          # ignore line comment
        when state.scan(/\/\*/)
          scan_block_comment(state)
        when matched = state.scan(TOKENS_RE)
          state.add_token(TOKENS.fetch(matched))
        when state.scan(/[ \r\t]/)
          # ignore whitespace
        when state.scan(/\n/)
          state.line += 1
        when state.scan(/"/)
          scan_str(state)
        when number = state.scan(/\d+(\.\d+)?/)
          state.add_token(:NUMBER, literal: number.to_f)
        when identifier = state.scan(/[a-zA-Z_]\w*/)
          type = KEYWORDS.fetch(identifier, :IDENTIFIER)
          state.add_token(type)
        else
          state.errors << Error.new(line: state.line, message: "Unexpected character.")
          state.scan(/./) # keep scanning
        end
      end

      # TODO
      fail unless state.errors.empty?

      state.add_token(:EOF, text: "")
      state.tokens
    end

    private

    def scan_str(state)
      text = ?"
      loop do
        case
        when state.scan(/"/)
          text << ?"
          state.add_token(:STRING, text:, literal: text[1..-2])
          return
        when state.scan(/\n/)
          text << ?\n
          state.line += 1
        when state.eos?
          state.errors << Error.new(line: state.line, message: "Unterminated string.")
          return
        when c = state.scan(/(?~"|\n)/)
          text << c
        else
          fail "unreachable!"
        end
      end
    end

    def scan_block_comment(state)
      loop do
        case
        when state.scan(/\/\*/)
          scan_block_comment(state)
        when state.scan(/\*\//)
          return
        when state.scan(/\n/)
          state.line += 1
        when state.eos?
          state.errors << Error.new(line: state.line, message: "Unterminated block comment.")
          return
        when state.scan(/./)
          # no-op
        else
          fail "unreachable!"
        end
      end
    end
  end
end
