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

      word_id_map = {}
      state_id_map = {}

      chunker.each_with_index do |chunk, idx|
        tokens = [""] * @chain.rank + tokenizer.tokenize(chunk) + [""]
        tokens.each_cons(@chain.rank+1) do |parts|
          parts.map! do |word|
            word_id = word_id_map[word] ||= db[:words].where(:word => word).get(:id)
            unless word_id
              word_id_map[word] = db[:words].insert(:word => word)
            end
          end

          state_string = parts[0..-2].join(",")
          state_id = state_id_map[state_string] ||= db[:states].where(:list => state_string).get(:id)
          unless state_id
            state_id = state_id_map[state_string] = db[:states].insert(:list => state_string)
          end

          db[:pairings].insert(:chain_id => @chain.id, :state_id => state_id, :word_id => parts[-1])

          print "Processing...#{idx}\r" if idx % 100 == 0
        end
      end
    end
  end
end
