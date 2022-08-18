module Lox

  class Error < StandardError
    attr_reader :token, :message

    def initialize(token, message)
      @token, @message = token, message
    end
  end

  class ParseError < Error
    def initialize(token, message)
      where = token.type == :EOF ? "end" : "'#{token.lexeme}'"

      error = "Error"
      error << " at #{where}" unless where.empty?

      super(token, "[line #{token.line}] #{error}: #{message}")
    end
  end

  RuntimeError = Class.new(Error)
  ResolverError = Class.new(Error)

end
