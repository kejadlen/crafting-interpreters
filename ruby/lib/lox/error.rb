module Lox
  class Error < StandardError
  end

  class ParseError < Error
    def initialize(token, message)
      where = token.type == :EOF ? "end" : "'#{token.lexeme}'"

      error = "Error"
      error << " at #{where}" unless where.empty?
      super("[line #{token.line}] #{error}: #{message}")
    end
  end

  class RuntimeError < Error
    attr_reader :token

    def initialize(token, message)
      @token = token
      super(message)
    end
  end
end
