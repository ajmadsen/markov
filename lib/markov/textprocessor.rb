require 'sequel'
require 'markov/models'

module Markov
  class TextProcessor
    @STRATEGIES = [:dumb].freeze

    def initialize(chain, rank, strategy = self.class.strategies.first)
      @chain = Chain.where(:name => chain, :rank => rank).first || Chain.create(:name => chain, :rank => rank)
      if self.class.strategies.include? strategy
        @strategy = strategy
      else
        raise ArgumentError, "#{self.class.name} does not provide strategy #{strategy}"
      end
    end

    def process(file)
      word_id = {}
      group_id = {}
      Sequel::Model.db.transaction do
        File.open(file) do |f|
          line_count = f.read.count("\n")
          f.rewind
          f.readlines.each_with_index do |line, idx|
            fragments = [""] * @chain.rank + line.split + [""]
            fragments.each_cons(@chain.rank + 1).each do |groups|
              word_list = groups.map do |word|
                word_id[word] ||= Word.find_or_create(:word => word)
              end
              group_string = word_list[0..-2].map(&:id).join(",")
              group = group_id[group_string] ||= Group.find_or_create(:list => group_string)
              @chain.add_pairing(:group => group, :word => word_list[-1])
              print "#{idx}/#{line_count}\r" if idx % 100 == 0
            end
          end
        end
      end
    end

    def self.strategies
      @STRATEGIES
    end
  end
end
