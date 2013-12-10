def generate(rank)
  running = [""] * rank
  generated = []
  selected = 0

  while selected != ""
    choices = $digraph[running]
    if choices.is_a? Hash
      expanded = choices.map {|k, v| [k] * v}
      choices = expanded.flatten
      $digraph[running] = choices
    end
    selected = choices.sample
    generated << selected
    running << selected
    running.shift
  end
  generated
end

if ARGV.length < 4
  raise "Usage: $0 <data> <rank> <#gens> <words min> <words max>"
end

$digraph = {}
File.open(ARGV[0]) do |f|
  $digraph = Marshal.load(f.read)
end

rank = ARGV[1].to_i
ntimes = ARGV[2].to_i
wmin = ARGV[3].to_i
wmax = ARGV[4].to_i

puts "Generating #{ntimes} sentences between #{wmin} and #{wmax}, looking back #{rank} words."

ntimes.times do
  arr = []
  while arr.length < wmin+1 || arr.length > wmax+1
    arr = generate rank
  end
  line = arr.join
  #line = arr.join(" ")
  #line.gsub!(/ ([!?"'“”‘’,-\.\*])/, '\1')
  puts line.strip
  puts ""
end
