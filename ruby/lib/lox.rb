#!/usr/bin/env ruby -w

require_relative "lox/error"
require_relative "lox/expr"
require_relative "lox/scanner"
require_relative "lox/token"

module Lox
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
end
