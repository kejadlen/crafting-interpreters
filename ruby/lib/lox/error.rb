module Lox
  class Error < StandardError
    def initialize(line:, where: "", message:)
      @line, @where, @message = line, where, message
    end

    def to_s
      "[line #@line] Error#@where: #@message"
    end
  end
end
