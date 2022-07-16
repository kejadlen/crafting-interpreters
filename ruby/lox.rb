#!/usr/bin/env ruby -w

module Lox
  class << self
    @had_error = false
  end

  def self.run_prompt
    loop do
      print "> "
      line = gets
      break if line.empty?
      run(line)
      @had_error = false
    end
  end

  def self.run_file(io)
    run(io.read)

    exit 65 if @had_error
  end

  def self.run(src)
    scanner = Scanner.new(src)
    tokens = scanner.scan()

    tokens.each do |token|
      puts token
    end
  end

  def self.error(line, msg)
    report(line, "", msg)
  end

  def self.report(line, where, message)
    puts "[line #{line}] Error#{where}: #{message}"
    @had_error = true;
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
