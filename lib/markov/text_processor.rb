require 'sequel'
require 'markov/models'
require 'markov/strategies'

module Markov
  class TextProcessor
    def initialize(chain, rank, chunker = :line, tokenizer = :naive)
      @chain = Chain.find_or_create(:name => chain, :rank => rank)
      @chunker = ChunkingStrategy.find(chunker) or raise ArgumentError, "#{chunker} is not a valid chunker strategy"
      @tokenizer = TokenizingStrategy.find(tokenizer) or raise ArgumentError, "#{tokenizer} is not a valid tokenizer strategy"
    end

    def process(io)
      chunker = @chunker.new io
      tokenizer = @tokenizer.new
      db = Sequel::Model.db

      chunker.each_with_index do |chunk, idx|
        tokens = [""] * @chain.rank + tokenizer.tokenize(chunk) + [""]
        tokens.each_cons(@chain.rank+1) do |parts|
          state_list = parts[0..-2]
          next_word_string = parts[-1]

          next_word = db[:words].where(:word => next_word_string).get(:id)
          unless next_word
            next_word = db[:words].insert(:word => next_word_string)
          end

          state_map = db[:words].where(:word => state_list).to_hash(:word, :id)
          state_string = state_list.map {|w| state_map[w]}.join(",")
          state = db[:states].where(:list => state_string).get(:id)
          unless state
            state = db[:states].insert(:list => state_string)
          end

          db[:pairings].insert(:chain_id => @chain.id, :state_id => state, :word_id => next_word)

          print "Processing...#{idx}\r" if idx % 100 == 0
        end
      end
    end
  end
end
