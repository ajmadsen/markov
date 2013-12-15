require 'markov/strategies'

module Markov
  class LineChunker < ChunkingStrategy
    @implements = :line

    def initialize(io, options={})
      super
      @options = {
        :every => 1,
        :join => " "
      }.merge options
    end

    def each
      @io.each.each_slice(@options[:every]) do |chunk|
        yield chunk.join(@options[:join])
      end
    end

    include Enumerable
  end
end
