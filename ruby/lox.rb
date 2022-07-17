#!/usr/bin/env ruby -w

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
    Runner.new(src).run
  end

  def self.error(line, msg)
    raise Error(line:, message:)
  end

  class Runner
    def initialize(scanner:)
      @scanner = scanner
    end

    def run(src)
      @scanner.scan(src)
    end
  end

  class Scanner
    def scan(src)
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
