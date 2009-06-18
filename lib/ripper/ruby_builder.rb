require 'ripper'
require 'ruby'
require 'ripper/ruby_builder/token'
require 'ripper/ruby_builder/stack'

Dir[File.dirname(__FILE__) + '/ruby_builder/events/*.rb'].each { |file| require file }

class Ripper
  class RubyBuilder < Ripper::SexpBuilder
    class << self
      def build(src)
        new(src).parse
      end
    end

    WHITESPACE        = [:@sp, :@nl, :@ignored_nl, :@comment]
    OPENERS           = [:@lparen, :@lbracket, :@lbrace, :@class, :@module, :@def, :@begin,
                         :@while, :@until, :@for, :@if, :@elsif, :@else, :@unless, :@case, :@when]
    KEYWORDS          = [:@alias, :@and, :@BEGIN, :@begin, :@break, :@case, :@class, :@def, :@defined, 
                         :@do, :@else, :@elsif, :@END, :@end, :@ensure, :@false, :@for, :@if, :@in, 
                         :@module, :@next, :@nil, :@not, :@or, :@redo, :@rescue, :@retry, :@return, 
                         :@self, :@super, :@then, :@true, :@undef, :@unless, :@until, :@when, :@while, 
                         :@yield]
    
    UNARY_OPERATORS   = [:'@+', :'@-', :'@!', :'@~', :@not]
    BINARY_OPERATORS  = [:'@**', :'@*', :'@/', :'@%', :'@+', :'@-', :'@<<', :'@>>', :'@&', :'@|', :'@^', 
                         :'@>', :'@>=', :'@<', :'@<=', :'@<=>', :'@==', :'@===', :'@!=', :'@=~', :'@!~', 
                         :'@&&', :'@||', :@and, :@or]
    TERNARY_OPERATORS = [:'@?', :'@:']
    ASSIGN_OPERATORS  = [:'@=', :'@+=', :'@-=',:'@*=', :'@**=', :'@/=', :'@[]=']
    ACCESS_OPERATORS  = [:'@[]']

    OPERATORS = UNARY_OPERATORS + BINARY_OPERATORS + TERNARY_OPERATORS + ASSIGN_OPERATORS + ACCESS_OPERATORS


    include Lexer, Statements, Const, Method, Call, Block, Args, Assignment, Operator,
            If, Case, For, While, Identifier, Literal, String, Symbol, Array, Hash

    attr_reader :src, :filename, :stack

    def initialize(src, filename = nil, lineno = nil)
      @src = src || filename && File.read(filename)
      @filename = filename
      @whitespace = ''
      @stack = []
      @stack = Stack.new
      super
    end

    protected

      def position
        [lineno - 1, column]
      end

      def push(sexp)
        stack.push(Token.new(*sexp))
      end

      def pop(*args)
        options = args.last.is_a?(::Hash) ? args.pop : {}
        if types = options[:ignore]
          stack_ignore(types) { stack.pop(*args << options) }
        else
          stack.pop(*args << options)
        end
      end
      
      def pop_token(*types)
        options = types.last.is_a?(::Hash) ? types.pop : {}
        options[:max] = 1
        pop_tokens(*types << options).first
      end

      def pop_tokens(*types)
        # options = types.last.is_a?(::Hash) ? types.pop : {}
        # types.map { |type| pop(type, options).map { |token| build_token(token) } }.flatten.compact
        pop(*types).map { |token| build_token(token) }.flatten.compact
      end
      
      def pop_operator(options = {})
        pop_token(*OPERATORS, options)
      end
      
      def pop_unary_operator(options = {})
        pop_token(*UNARY_OPERATORS, options)
      end

      def pop_binary_operator(options = {})
        pop_token(*BINARY_OPERATORS, options)
      end

      def pop_ternary_operators(options = {})
        pop_tokens(*TERNARY_OPERATORS, options)
      end

      def pop_assignment_operator(options = {})
        pop_token(*ASSIGN_OPERATORS, options)
      end

      def pop_whitespace
        pop(*WHITESPACE).reverse.map { |token| token.value }.join
      end

      def stack_ignore(*types, &block)
        stack.ignore_types(*types, &block)
      end
      
      def build_token(token)
        Ruby::Token.new(token.value, token.position, token.whitespace) if token
      end
      
      def extract_src(from, to)
        lines = src.split("\n")[from[0]..to[0]]
        lines[0] = lines.first[from[1]..-1]
        lines[lines.length - 1] = lines.last.slice(0, to[1])
        lines.join("\n")
      end
  end
end