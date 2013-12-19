module Markov
  class ChunkingStrategy
    @implements = :null

    class << self
      attr_reader :implements

      def inherited(base)
        @strategies ||= []
        @strategies << base
      end

      def find(strategy)
        return nil unless @strategies
        @strategies.find {|s| s.implements == strategy}
      end

      def strategies
        @strategies
      end
    end

    def initialize(io=nil, options={})
      @io = io
      @options = options
    end

    def each
      yield nil
    end

    include Enumerable
  end

  class TokenizingStrategy
    @implements = :null

    class << self
      attr_reader :implements

      def inherited(base)
        @strategies ||= []
        @strategies << base
      end

      def find(strategy)
        return nil unless @strategies
        @strategies.find {|s| s.implements == strategy}
      end

      def strategies
        @strategies
      end
    end

    def tokenize(chunk)
      nil
    end
  end
end

