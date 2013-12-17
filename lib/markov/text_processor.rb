require 'markov/database'
require 'markov/strategies'

module Markov
  class TextProcessor
    def initialize(db, chain, rank, chunker = :line, tokenizer = :naive)
      @db = db
      @chain_id = @db.get_chain(chain, rank) || @db.put_chain(chain, rank)
      @rank = rank
      @chunker = ChunkingStrategy.find(chunker) or raise ArgumentError, "#{chunker} is not a valid chunker strategy"
      @tokenizer = TokenizingStrategy.find(tokenizer) or raise ArgumentError, "#{tokenizer} is not a valid tokenizer strategy"
    end

    def process(io)
      chunker = @chunker.new io
      tokenizer = @tokenizer.new
      size = io.stat.size?
      bytes = 0

      @db.transaction do
        chunker.each_with_index do |chunk, idx|
          bytes += chunk.size

          tokens = [""] * @rank + tokenizer.tokenize(chunk) + [""]
          tokens.each_cons(@rank+1) do |parts|
            parts.map! do |word|
              @db.get_word(word) || @db.put_word(word)
            end

            state_string = parts[0..-2].join(",")
            state_id = @db.get_state(state_string) || @db.put_state(state_string)

            @db.put_association @chain_id, state_id, parts[-1]
          end

          yield bytes, size if block_given?
        end
      end
    end
  end
end
