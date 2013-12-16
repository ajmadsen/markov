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

      insert_word = db[:words].prepare(:insert, :insert_word, :word => :$word)
      select_word = db[:words].where(:word => :$word).prepare(:first, :select_word)
      insert_state = db[:states].prepare(:insert, :insert_state, :list => :$list)
      select_state = db[:states].where(:list => :$list).prepare(:first, :select_state)
      insert_pairing = db[:pairings].prepare(:insert, :insert_pairing, :chain_id => @chain.id, :state_id => :$state_id, :word_id => :$word_id)

      db.transaction do
        chunker.each_with_index do |chunk, idx|
          GC.disable
          tokens = [""] * @chain.rank + tokenizer.tokenize(chunk) + [""]
          tokens.each_cons(@chain.rank+1) do |parts|
            parts.map! do |word|
              word_id_map[word] ||= (select_word.call(:word => word) || {:id => insert_word.call(:word => word)})[:id]
            end

            state_string = parts[0..-2].join(",")
            state_id = state_id_map[state_string] ||= (select_state.call(:list => state_string) || {:id => insert_state.call(:list => state_string)})[:id]

            insert_pairing.call(:state_id => state_id, :word_id => parts[-1])

            print "Processing...#{idx}\r" if idx % 100 == 0
          end
          GC.enable
        end
      end
    end
  end
end
