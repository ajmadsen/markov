require 'markov/strategies'

module Markov
  class LineGenerator < GeneratingStrategy
    @implements = :line

    def generate(number)
      raise ArgumentError, "number must be positive" if number <= 0
      generated = []
      while generated.size < number
        line = []
        state = [""] * @rank
        current = nil
        while current != ""
          state_id = @db.get_state(state.map {|w| @db.get_word w}.join ",")
          current = @db.get_associations(@chain, state_id).sample
          line << current
          state << current
          state.shift
          p current
        end
        line = line.join(" ").strip
        length = line.split.size
        next if @opts[:min] and @opts[:min] > 0 and length < @opts[:min]
        next if @opts[:max] and @opts[:max] > 0 and @opts[:max] < length
        generated << line
      end
      generated
    end
  end
end
