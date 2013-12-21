require 'markov/strategies'

module Markov
  class SentenceChunker < ChunkingStrategy
    class << self
      def defaults
        {
          :every => 1,
          :join => " "
        }
      end
    end

    PUNCTUATION = /(\.\?!)/

    @implements = :sentence

    def each
      buffer = []
      @io.each_line do |line|
        buffer << line.split(PUNCTUATION)
        while buffer.length >= @options[:every]
          yield buffer.shift(@options[:every]).join(@options[:join])
        end
      end
    end

    include Enumerable
  end
end
