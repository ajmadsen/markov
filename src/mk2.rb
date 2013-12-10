require 'sqlite3'

$procession = []
$lookup = {}

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
  #parts = [""] * rank + line.split + [""]
  parts = [""] * rank + line.scan(/(\w+|\W)/).flatten + [""]
  parts[0..-(rank +1)].each_index do |i|
    key = parts[i..(i+rank-1)].inject([]) { |t, p| t << p }
    $procession << [key, parts[i+rank]]
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

puts "Sorting array of #{$procession.length} elements."

$procession.sort!

last = $procession[0][0]
running = []
id = -1
count = 0
$procession.each do |v|
  if last != v[0]
    #print ""
    #print "Done with #{last}"
    #print running
    $lookup[last] = running
    running = []
    last = v[0]
    count += 1
    printf "#{count}\r" if count % 100 == 0
  end
  running << v[1]
end

File.open(ARGV[1], "w+") do |f|
  f.write Marshal.dump($lookup)
end

#p $lookup
