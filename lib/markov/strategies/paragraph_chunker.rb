require 'markov/strategies'

module Markov
  class ParagraphChunker < ChunkingStrategy
    class << self
      def defaults
        {
          :every => 1,
          :join => " "
        }
      end
    end

    @implements = :paragraph

    def each
      @io.each("\n\n").each_slice(@options[:every]) do |paragraph|
        yield paragraph.join(@options[:join])
      end
    end

    include Enumerable
  end
end
