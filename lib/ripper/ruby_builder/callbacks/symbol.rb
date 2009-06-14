class Ripper
  class RubyBuilder < Ripper::SexpBuilder
    module Symbol
      def on_symbol_literal(symbol)
        symbol
      end
      
      def on_symbol(token)
        token = token.token if token.respond_to?(:token)
        token = token.value if token.respond_to?(:value)

        ldelim = pop_delim(:@symbeg)
        Ruby::Symbol.new(token, ldelim)
      end

      def on_dyna_symbol(symbol)
        symbol.rdelim = pop_delim(:@tstring_end)
        symbol
      end
    end
  end
end