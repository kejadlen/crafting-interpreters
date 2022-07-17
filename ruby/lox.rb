#!/usr/bin/env ruby -w

require "strscan"

module Lox
  class Error < StandardError
    def initialize(line:, where: "", message:)
      @line, @where, @message = line, where, message
    end

    def to_s
      "[line #@line] Error#@where: #@message"
    end
  end

  def self.run_prompt
    loop do
      print "> "
      line = gets
      break if line.empty?
      begin
        run(line)
      rescue Error => e
        puts e.message
      end
    end
  end

  def self.run_file(io)
    run(io.read)
  rescue Error
    puts e.message
    exit 65
  end

  def self.run(src)
    Runner.new.run(src)
  end

  def self.error(line, msg)
    raise Error(line:, message:)
  end

  class Runner
    def initialize(scanner: Scanner.new)
      @scanner = scanner
    end

    def run(src)
      @scanner.scan(src).each do |token|
        puts token
      end
    end
  end

  class Scanner
    KEYWORDS = {
      and:    :AND,
      class:  :CLASS,
      else:   :ELSE,
      false:  :FALSE,
      for:    :FOR,
      fun:    :FUN,
      if:     :IF,
      nil:    :NIL,
      or:     :OR,
      print:  :PRINT,
      return: :RETURN,
      super:  :SUPER,
      this:   :THIS,
      true:   :TRUE,
      var:    :VAR,
      while:  :WHILE,
    }.transform_keys(&:to_s)

    State = Struct.new(:ss, :tokens, :errors, :line) do
      def eos? = ss.eos?
      def scan(re) = ss.scan(re)
      def pos = ss.pos

      def add_token(type, text: nil, literal: nil)
        text ||= ss.matched
        self.tokens << Token.new(type, text, literal, line)
      end
    end

    def scan(src)
      state = State.new(StringScanner.new(src), [], [], 1)

      until state.eos?
        case
        when state.scan(/\(/) then state.add_token(:LEFT_PAREN)
        when state.scan(/\)/) then state.add_token(:RIGHT_PAREN)
        when state.scan(/\{/) then state.add_token(:LEFT_BRACE)
        when state.scan(/}/)  then state.add_token(:RIGHT_BRACE)
        when state.scan(/,/)  then state.add_token(:COMMA)
        when state.scan(/\./) then state.add_token(:DOT)
        when state.scan(/-/)  then state.add_token(:MINUS)
        when state.scan(/\+/) then state.add_token(:PLUS)
        when state.scan(/;/)  then state.add_token(:SEMICOLON)
        when state.scan(/\*/) then state.add_token(:STAR)
        when state.scan(/!=/) then state.add_token(:BANG_EQUAL)
        when state.scan(/!/)  then state.add_token(:BANG)
        when state.scan(/==/) then state.add_token(:EQUAL_EQUAL)
        when state.scan(/=/)  then state.add_token(:EQUAL)
        when state.scan(/<=/) then state.add_token(:LESS_EQUAL)
        when state.scan(/</)  then state.add_token(:LESS)
        when state.scan(/>=/) then state.add_token(:GREATER_EQUAL)
        when state.scan(/>/)  then state.add_token(:GREATER)
        when state.scan(/\/\/(?~\n)+/)       # ignore line comment
        when state.scan(/\/\*/)
          scan_block_comment(state)
        when state.scan(/\//) then state.add_token(:SLASH)
        when state.scan(/[ \r\t]/)    # ignore whitespace
        when state.scan(/\n/)         then state.line += 1
        when state.scan(/"/)
          scan_str(state)
        when number = state.scan(/\d+(\.\d+)?/)
          state.add_token(:NUMBER, literal: number.to_f)
        when identifier = state.scan(/[a-zA-Z_]\w+/)
          type = KEYWORDS.fetch(identifier, :IDENTIFIER)
          state.add_token(type)
        else state.scan(/./) # keep scanning
          state.errors << Error.new(line: state.line, message: "Unexpected character.")
        end
      end

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
        when c = state.scan(/./)
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
        when c = state.scan(/./)
          # no-op
        else
          fail "unreachable!"
        end
      end
    end
  end

  Token = Struct.new(:type, :lexeme, :literal, :line) do
    def to_s
      "#{type} #{lexeme} #{literal}"
    end
  end
end

if __FILE__ == $0
  puts "Usage: #$0 [script]" or exit 64 if ARGV.length > 1

  if ARGV.empty?
    Lox.run_prompt
  else
    Lox.run_file(ARGF)
  end
end
