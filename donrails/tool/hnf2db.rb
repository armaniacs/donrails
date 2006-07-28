#!/usr/bin/env ruby

ADDITIONAL_LOAD_PATHS = ["../../donrails/lib"]
ADDITIONAL_LOAD_PATHS.reverse.each { |dir| $:.unshift(dir) if File.directory?(dir) }

require '../../rails/config/environment'
require 'antispam'

require 'active_record'
require 'logger'
require '../../donrails/app/models/article'
require '../../donrails/app/models/category'
require '../../donrails/app/models/comment'
require '../../donrails/app/models/picture'

#ActiveRecord::Base.logger = Logger.new("/tmp/hnf2db.log")

$KCODE = "UTF8"
require 'kconv'
require 'getoptlong'
require 'readline'

class Hnfdb
  def initialize
  end
    
  def hnfinput(y)
    article_id = 0
    category_id = 0

    aris0 = Article.new("title" => y['title'], 
                       "body" => y['text'],
                       "article_date" => y['ymd'], 
                       "article_mtime" => y['mtime'], 
                       "hnfid" => y['hnfid'], 
                       "size" => y['text'].size, 
                       "format" => "hnf")
    if y['cat']
      y['cat'].each do |cat|
        aris1 = Category.find(:first, :conditions => ["name = ?", cat])
        
        if aris1
          aris0.categories.push_with_attributes(aris1)
        else
          aris2 = Category.new("name" => cat)
          aris2.save
          aris0.categories.push_with_attributes(aris2)
        end
      end
    end
    aris0.save
  end # hnfinput

  def commentinput(y)
    article_id = 0
    comment_id = 0

    aris0 = Article.find(:first, :conditions => ["hnfid = ?", y["hnfid"]])
    article_id = aris0.id

    aris1 = Comment.new("password" => y["password"],
                        "date" => y["date"],
                        "title" => y["title"],
                        "author" => y["author"],
                        "url" => y["url"],
                        "ipaddr" => y["ipaddr"],
                        "body" => y["body"])
    comment_id = aris1.id

    if article_id == 0
      print "(orphane) #{comment_id}, #{y["article_title"]}\n"
    end
    aris1.articles.push_with_attributes(aris0)
    aris1.save
  end
end

def addhnf(hdb,f)
  if f =~ /d(\d{4})(\d{2})(\d{2})\.hnf/
    ymd = $1 + '-' + $2 + '-' + $3
    hnfdate = $1 + $2 + $3

    fftmp = open(f, "r")
    mtime = fftmp.mtime
    ftmpread = fftmp.read
    ftmp = Kconv.toutf8(ftmpread).split(/\n/)
    fftmp.close
    ftmp.shift

    y = Hash.new
    y['ymd'] = ymd
    y['mtime'] = mtime
    y['text'] = ''
    daynum = 0

    ftmp.each do |x|
      if x =~ /^(CAT|NEW|LNEW)\s+.+/
        if y['title']
          hdb.hnfinput(y)
          y.clear
          y['ymd'] = ymd
          y['mtime'] = mtime
          y['text'] = ''
        end
      end

      if x =~ /^CAT\s+(.+)/
        y['cat'] = $1.split(/\W+/)
        next
      end

      if x =~ /^(NEW|LNEW)\s+(.+)/
        y['title'] = $2
        daynum += 1
        y['hnfid'] = "#{hnfdate}#{daynum}"
        next
      end

      y['text'] += x + "\n"

    end
    hdb.hnfinput(y)
  end
end

def addcomment(hdb,f)
  fftmp = open(f, "r")

  while fftmp.gets
#    t0 = $_
    t0 = Kconv.toutf8($_)
    oneline = t0.split(/\t/)
    p oneline
    if oneline[2] == "root"
#      line_id = oneline[1]
      hnfid = oneline[3]
      date = oneline[5]
      article_title = oneline[6]
      if article_title =~ /^\[\[(.*)\]\]$/
        article_title = $1
      end
    else
      password = oneline[0]
#      line_id = oneline[1]
      date = oneline[5]
      title = oneline[6]
      author = oneline[7]
      url = oneline[9]
      ipaddr = oneline[10]
      body = oneline[11]

      y = Hash.new
      y = { 
        "password" => password,
        "article_title" => article_title,
        "date" => date, "title" => title, "author" => author, "url" => url,
        "ipaddr" => ipaddr, "body" => body, "hnfid" => hnfid
      }
      hdb.commentinput(y)
    end
  end
end

adapter = nil
database = nil
dbfile = nil
host = nil
username = nil
password = nil

parser = GetoptLong.new
parser.set_options(['--adapter', '-a', GetoptLong::REQUIRED_ARGUMENT],
                   ['--database', '-d', GetoptLong::REQUIRED_ARGUMENT],
                   ['--dbfile', GetoptLong::REQUIRED_ARGUMENT],
                   ['--host', '-h', GetoptLong::REQUIRED_ARGUMENT],
                   ['--username', '-u', GetoptLong::REQUIRED_ARGUMENT],
                   ['--password', '-p', GetoptLong::REQUIRED_ARGUMENT])

parser.each_option do |name, arg|
  case name
  when "--adapter"
    adapter = arg.to_s
  when "--database"
    database = arg
  when "--dbfile"
    dbfile = arg
  when "--host"
    host = arg
  when "--username"
    username = arg
  when "--password"
    password = arg
  end
end

if adapter == nil
  print "Select database adapter from mysql/postgresql/sqlite/sqlite3.\n"
  buf = Readline.readline("> ", true)
  if buf =~ /(mysql|postgresql|sqlite|sqlite3)/
    adapter = buf
  else
    print "input supported adapter!\n"
    exit
  end
end

if adapter =~ /sqlite3?/
  if dbfile == NIL
    print "Select database file for sqlite0/3.\n"
    buf = Readline.readline("> ", true)
    dbfile = buf
  end
  unless File.exists? dbfile
    print "Please run \"#{adapter} #{dbfile} < tables-sqlite.txt\" befor runnig #{$0}.\n"
    exit
  end
  ActiveRecord::Base.establish_connection(:adapter  => adapter, :dbfile => dbfile)
else
  if database == nil
    print "Input database name.\n"
    buf = Readline.readline("> ", true)
    database = buf
  end
  if host == nil
    print "Input database hostname.\n"
    buf = Readline.readline("> ", true)
    host = buf
  end
  if username == nil
    print "Input database username.\n"
    buf = Readline.readline("> ", true)
    username = buf
  end
  if password == nil
    print "Input database password.\n"
    buf = Readline.readline("> ", true)
    password = buf
  end
  ActiveRecord::Base.establish_connection(:adapter  => adapter, :database => database, :host => host, :username => username, :password => password)

end

hdb = Hnfdb.new


ARGV.each do |f|
  p f
  if f =~ /d\d{8}.hnf/
    addhnf(hdb,f)
  else
    addcomment(hdb,f)
  end
end



