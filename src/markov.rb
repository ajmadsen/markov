require 'sqlite3'

$procession = []


def filter(line)
  line.rstrip!
  line.downcase!
  line.gsub! /<.*?>/, ""
  line.gsub! "&amp;", "&"
  line.gsub! "&quot;", "\""
  line.gsub! "&apos;", "\'"
  line.gsub! "&gt;", ">"
  line.gsub! "&lt;", "<"
end

def process(line, rank)
  parts = [""] * rank + line.scan(/(\w+|\W)/).flatten + [""]
  $db.prepare do |db|
    parts.each_cons(rank+1) do |line|

    end
  end
end

if ARGV.length < 3
  raise "Usage: $0 <source> <database> <rank>"
end

rank = ARGV[2].to_i
$db = SQLite3::Database.new(ARGV[1])

sql =<<SQL
  drop table if exists Words;
  drop table if exists Groups;
  drop table if exists Succ;

  create table Words (
    id int not null,
    word text not null
  );

  create table Groups (
    id int not null,
    word_id int foreign key references Words(id),
    next_id int
  );

  create table Succ (
    id int not null,
    group_id int foreign key references Groups(id),
    next_id int foreign key references Words(id)
  );

  PRAGMA main.page_size = 4096;
  PRAGMA main.cache_size=10000;
  PRAGMA main.locking_mode=EXCLUSIVE;
  PRAGMA main.synchronous=NORMAL;
  PRAGMA main.journal_mode=WAL;
SQL

$db.execute_batch(sql)

file = File.open(ARGV[0])
num_lines = file.read.count("\n")
file.rewind
file.readlines.each_with_index do |line, i|
  printf "#{i}/#{num_lines}\r" if i % 100 == 0
  filter(line)
  process(line)
end
file.close

$db.close

