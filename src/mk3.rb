require 'sqlite3'

$procession = []
$lookup = {}
$buffer = ""

def filter(line)
  line.rstrip!
  line.downcase!
  line.gsub! /<.*?>/, ""
  line.gsub! "&amp;", "&"
  line.gsub! "&quot;", "\""
  line.gsub! "&apos;", "\'"
  line.gsub! "&gt;", ">"
  line.gsub! "&lt;", "<"
  #line.gsub! /([!?"'“”‘’,-\.\*])/, ' \1 '
end

def process(line, rank)
  $buffer = $buffer.rstrip + " " + line.lstrip
  match = $buffer.match(/([\.\?!])/)
  return if not match
  line, $buffer = $buffer.split(/[\.\?!] */, 2)
  line += match[1]
  parts = [""] * rank + line.scan(/(\w+|\W)/).flatten + [""]
  parts.each_cons(rank+1) do |line|
    key = line[0,rank]
    succ = line[-1]
    if $lookup.include? key
      if $lookup[key].include? succ
        $lookup[key][succ] += 1
      else
        $lookup[key][succ] = 1
      end
    else
      newval = Hash.new
      newval[succ] = 1
      $lookup[key] = newval
    end
  end
end

if ARGV.length < 3
  raise "Needs an argument file and an output and a rank"
end

rank = ARGV[2].to_i

file = File.open(ARGV[0])
num_lines = file.read.count("\n")
file.rewind
file.readlines.each_with_index do |line, i|
  printf "#{i}/#{num_lines}\r" if i % 100 == 0
  filter(line)
  next if line.empty?
  process(line, rank)
end
file.close

puts "Dumping table to #{ARGV[1]}"

File.open(ARGV[1], "w+") do |f|
  f.write Marshal.dump($lookup)
end
