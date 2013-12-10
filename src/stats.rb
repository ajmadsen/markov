if ARGV.length < 1
  raise "Usage: $0 <data>"
end

data = {}
File.open(ARGV[0]) do |f|
  data = Marshal.load(f.read)
end

distrib = {}
data.keys.each do |v|
  nexts = data[v]
  len = nexts.length
  existings = distrib[len]
  distrib[len] = existings.nil? ? 1 : existings + 1
end

distrib.keys.sort.each do |k|
  puts "#{k} : #{distrib[k]}"
end
