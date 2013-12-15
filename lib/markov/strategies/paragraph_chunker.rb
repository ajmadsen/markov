require 'markov/strategies'

module Markov
  class ParagraphChunker < ChunkingStrategy
    @implements = :paragraph

    def initialize(io, options={})
      super
      @options = {
        :every => 1,
        :join => " "
      }.merge(options)
    end

    def each
      @io.each("\n\n").each_slice(@options[:every]) do |paragraph|
        yield paragraph.join(@options[:join])
      end
    end

    include Enumerable
  end
end
