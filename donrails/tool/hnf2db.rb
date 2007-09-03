#!/usr/bin/env ruby

$KCODE = "UTF8"
require 'kconv'
require 'getoptlong'
require 'readline'
parser = GetoptLong.new
mode = 'production'
unsave = false
verbose = nil

def usage
  puts "
hnf2db.rb [options] hnffile
  hnffile: h14m format text.

Example:
  ruby hnf2db.rb -d /tmp/d20060101.hnf

Available options:

 -m mode\t: Usually use 'mode' options. Like
\t\t ruby hnf2db.rb -m production \t(production mode is default.)

 -p\t: Same as 'ruby hnf2db.rb -m production'

 -d\t: Same as 'ruby hnf2db.rb -m development'

 -t\t: Same as 'ruby hnf2db.rb -m test'

 -h\t: Show this message.

 --dry-run\t: Dry run (no save).

 -v\t: verbose output

"
  exit
end

parser.set_options(
                   ['--mode', '-m', GetoptLong::REQUIRED_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT],
                   ['--dry-run', GetoptLong::NO_ARGUMENT],
                   ['--development', '-d', GetoptLong::NO_ARGUMENT],
                   ['--production', '-p', GetoptLong::NO_ARGUMENT],
                   ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
                   ['--test', '-t', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--force"
    force = true
  when "--dry-run"
    unsave = true
  when "--defer_seconds"
    defer_seconds = arg.to_i
  when "--numbers"
    numbers = arg.to_i
  when "--mode"
    mode = arg.to_s
  when "--development"
    mode = 'development'
  when "--production"
    mode = 'production'
  when "--test"
    mode = 'test'
  when "--config"
    config = arg.to_s
  when "--verbose"
    verbose = true
  when "--usage"
    usage
  else
    usage
  end
end

ADDITIONAL_LOAD_PATHS = ["../../lib"]
ADDITIONAL_LOAD_PATHS.reverse.each { |dir| $:.unshift(dir) if File.directory?(dir) }

require File.dirname(__FILE__) + '/../../config/environment'
fconf = open("#{File.dirname(__FILE__)}/../../config/database.yml", "r")
conf = YAML::load(fconf)
ActiveRecord::Base.establish_connection(conf["#{mode}"])

require 'antispam'

require 'active_record'
require 'logger'
require '../../app/models/article'
require '../../app/models/category'
require '../../app/models/dona_ca'
require '../../app/models/comment'
require '../../app/models/picture'
require '../../app/models/enrollment'

#ActiveRecord::Base.logger = Logger.new("/tmp/hnf2db.log")


class Hnfdb
  attr :unsave, :true
  attr :verbose, :true

  def initialize
    @unsave = false
    @verbose = nil
  end
    
  def hnfinput(y)
    article_id = 0
    category_id = 0

    enr0 = Enrollment.new("title" => y['title'])
    enr0.save    unless @unsave
    p enr0, enr0.id
    arti0 = Article.new("title" => y['title'], 
                        "body" => y['text'],
                        "article_date" => y['ymd'], 
                        "article_mtime" => y['mtime'], 
                        "hnfid" => y['hnfid'], 
                        "size" => y['text'].size, 
                        "enrollment_id" => enr0.id,
                        "author_id" => 1,
                        "format" => "hnf")
    arti0.save unless @unsave
    p arti0 if @verbose

    if y['cat']
      y['cat'].each do |cat|
        cat0 = Category.find(:first, :conditions => ["name = ?", cat])
        
        if cat0
          # arti0.categories.push_with_attributes(cat0)
          dca = DonaCa.new(:category_id => cat0.id, :article_id => arti0.id)
          dca.save unless @unsave
          p dca if @verbose
        else
          cat1 = Category.new("name" => cat)
          cat1.save unless @unsave
          p cat1 if @verbose
          # arti0.categories.push_with_attributes(cat1)
          dca = DonaCa.new(:category_id => cat1.id, :article_id => arti0.id)
          dca.save unless @unsave
          p dca if @verbose
        end
      end
    end
    

  end # hnfinput

  def commentinput(y)
    article_id = 0
    comment_id = 0

    arti0 = Article.find(:first, :conditions => ["hnfid = ?", y["hnfid"]])
    article_id = arti0.id

    comm0 = Comment.new("password" => y["password"],
                        "date" => y["date"],
                        "title" => y["title"],
                        "author" => y["author"],
                        "url" => y["url"],
                        "ipaddr" => y["ipaddr"],
                        "body" => y["body"])
    comment_id = comm0.id

    if article_id == 0
      print "(orphane) #{comment_id}, #{y["article_title"]}\n"
    end
    comm0.articles.push_with_attributes(arti0)
    comm0.save unless @unsave
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
    t0 = Kconv.toutf8($_)
    oneline = t0.split(/\t/)
    p oneline
    if oneline[2] == "root"
      hnfid = oneline[3]
      date = oneline[5]
      article_title = oneline[6]
      if article_title =~ /^\[\[(.*)\]\]$/
        article_title = $1
      end
    else
      password = oneline[0]
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

##### start
hdb = Hnfdb.new
hdb.unsave = unsave
hdb.verbose = verbose
usage if ARGV.size == 0

ARGV.each do |f|
  p f
  if f =~ /d\d{8}.hnf/
    addhnf(hdb,f)
  else
    addcomment(hdb,f)
  end
end



