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

      def defaults
        {}
      end
    end

    def initialize(io, options={})
      @io = io
      @options = self.class.defaults.merge options
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

  class GeneratingStrategy
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

      def defaults
        {}
      end
    end

    def initialize(opts={})
      @opts = self.class.defaults.merge opts
    end

    def generate(number)
      [nil] * number
    end
  end
end

