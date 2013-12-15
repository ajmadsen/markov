require 'markov/strategies'

module Markov
  class WordTokenizer < TokenizingStrategy
    @implements = :word

    TOKENS = /(\w+|\W)/

    def tokenize(chunk)
      chunk.scan(TOKENS)
    end
  end
end
