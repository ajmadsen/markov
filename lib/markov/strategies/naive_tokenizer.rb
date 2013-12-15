require 'markov/strategies'

module Markov
  class NaiveTokenizer < TokenizingStrategy
    @implements = :naive

    def tokenize(chunk)
      chunk.split
    end
  end
end
