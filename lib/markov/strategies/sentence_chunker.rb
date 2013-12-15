require 'markov/strategies'

module Markov
  class SentenceChunker < ChunkingStrategy
    @implements = :sentence

    PUNCTUATION = /(\.\?\!)/

    def initialize(io, options={})
      super
      @options = {
        :every => 1,
        :join => " "
      }.merge options
    end

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
