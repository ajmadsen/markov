require 'sequel'
require 'markov/models'

module Markov
  class TextProcessor
    @STRATEGIES = [:dumb].freeze

    def initialize(chain, rank, strategy = self.class.strategies.first)
      @chain = Chain.find_or_create(:name => chain, :rank => rank)
      if self.class.strategies.include? strategy
        @strategy = strategy
      else
        raise ArgumentError, "#{self.class.name} does not provide strategy #{strategy}"
      end

      @data = ""
      @segments = []
      @pairings = {}
    end

    def process(file)
      @current_file = file
      slurp_file
      process_segments
      build_pairings
      dump_pairings
    end

    def self.strategies
      @STRATEGIES
    end

    private

      def slurp_file
        print "Loading file..."
        File.open(@current_file) do |f|
          @data += f.read
        end
        puts "done."
      end

      def process_segments
        print "Processing segments..."
        @segments += @data.split "\n"
        puts "done."
      end

      def build_pairings
        db = Sequel::Model.db
        word_map = {}
        group_map = {}
        unless word_map[""] = db[:words].where(:word => "").get(:id)
          word_map[""] = db[:words].insert(:word => "")
        end
        len = @segments.length
        db.transaction do
          @segments.each_with_index do |line, idx|
            line = [""] * @chain.rank + line.split + [""]
            line.each_cons(@chain.rank+1) do |parts|
              next_word = word_map[parts[-1]] ||= db[:words].where(:word => parts[-1]).get(:id)
              unless next_word
                next_word = word_map[parts[-1]] ||= db[:words].insert(:word => parts[-1])
              end
              #group_lookup = db[:words].where(:id => parts[0..-2]).to_hash(:word, :id)
              group = parts[0..-2].map {|w| word_map[w]}.join ","
              group_id = group_map[group] ||= db[:groups].where(:list => group).get(:id)
              unless group_id
                group_id = group_map[group] ||= db[:groups].insert(:list => group)
              end
              db[:pairings].insert(:chain_id => @chain.id, :group_id => group_id, :word_id => next_word)
              print "Building segments...#{idx}/#{len}\r" if idx % 100 == 0
            end
          end
        end
        puts "Building pairings...#{len} segments processed."
      end

      def dump_pairings
      end
  end
end
