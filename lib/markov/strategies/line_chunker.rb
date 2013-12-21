require 'markov/strategies'

module Markov
  class LineChunker < ChunkingStrategy
    class << self
      def defaults
        {
          :every => 1,
          :join => " "
        }
      end
    end

    @implements = :line

    def each
      @io.each.each_slice(@options[:every]) do |chunk|
        yield chunk.join(@options[:join])
      end
    end

    include Enumerable
  end
end
