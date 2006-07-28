#!/usr/bin/env ruby

$KCODE = "UTF8"
require 'kconv'
require 'dbi'
$dbfile = "#{ENV["HOME"]}/hnfdata.db"

class Hnfdb
  def initialize
  end

  def connect
    @dbh = DBI.connect("DBI:SQLite:#{$dbfile}")
    @dbh['AutoCommit'] = true
  end

  def disconnect
    @dbh.disconnect
  end


  def create_table_pictures
    begin
      @dbh.do("CREATE TABLE pictures (
         id       INTEGER PRIMARY KEY,
         name     VARCHAR,
         path      VARCHAR,
         size      INTEGER,
         content_type   VARCHAR,
         comment        VARCHAR
         )"
              )
    rescue
      p $!
    end
  end


  def create_table_comments
    begin
      @dbh.do("CREATE TABLE comments (
         id       INTEGER PRIMARY KEY,
         password    VARCHAR,

         date     TIMESTAMP,
         title     VARCHAR,
         author   VARCHAR,
         url      VARCHAR,

         ipaddr   VARCHAR,
         body     VARCHAR
         )"
              )
    rescue
      p $!
    end
  end


  def create_table_categories
    begin
      @dbh.do("CREATE TABLE categories (
         id       INTEGER PRIMARY KEY,
         name         VARCHAR NOT NULL UNIQUE
         )"
              )
    rescue
      p $!
    end
  end

  # format example: "hnf"
  def create_table_articles
    begin
      @dbh.do("CREATE TABLE articles (
         id       INTEGER PRIMARY KEY,
         title    VARCHAR,
         body     VARCHAR,
         size     INTEGER,
         article_date     TIMESTAMP,
         article_mtime    TIMESTAMP,
         hnfid    INTEGER,
         format   VARCHAR
         )"
              )
    rescue
      p $!
    end
  end

  def create_table_categories_articles
    begin
      @dbh.do("CREATE TABLE categories_articles (
         category_id       INTEGER NOT NULL,
         article_id       INTEGER NOT NULL,
         constraint fk_cp_category foreign key (category_id) references categories(id),
         constraint fk_cp_article foreign key (article_id) references articles(id),
         primary key (category_id, article_id)
         )"
              )
    rescue
      p $!
    end
  end

  def create_table_comments_articles
    begin
      @dbh.do("CREATE TABLE comments_articles (
         comment_id       INTEGER NOT NULL,
         article_id       INTEGER NOT NULL,
         constraint fk_cp_comment foreign key (comment_id) references comments(id),
         constraint fk_cp_article foreign key (article_id) references articles(id),
         primary key (comment_id, article_id)
         )"
              )
    rescue
      p $!
    end
  end

  def hnfinput(y)
    article_id = 0
    category_id = 0

    sth = @dbh.prepare("INSERT INTO articles (title, body, article_date, article_mtime, hnfid, size, format) VALUES(?,?,?,?,?,?,?)") 
    p y['title'], y['text'], y['ymd'], y['mtime'], y['hnfid']

    sth.execute(y['title'], y['text'], y['ymd'], y['mtime'], y['hnfid'], y['text'].size, "hnf")


    sth2 = @dbh.prepare("SELECT id FROM articles WHERE title = ? AND body = ? AND article_date = ? AND article_mtime = ?")
    sth2.execute(y['title'], y['text'], y['ymd'], y['mtime'])
    sth2.fetch do |row|
      article_id = row['id']
    end

    if y['cat']
      y['cat'].each do |cat|
        begin
          sth4 = @dbh.prepare("INSERT INTO categories (name) VALUES(?)")
          sth4.execute(cat)
        rescue
          p $!
        end
        
        sth5 = @dbh.prepare("SELECT id FROM categories WHERE name = ?")
        sth5.execute(cat)
        sth5.fetch do |row|
          category_id = row['id']
        end
        
        print "** article_id is #{article_id}, #{cat}'s category_id is #{category_id} **\n\n"
        
        begin
          sth6 = @dbh.prepare("INSERT INTO categories_articles (category_id, article_id) VALUES(?,?)")
          sth6.execute(category_id, article_id)
        rescue
          p $!
        end
      end
    end
  end # hnfinput

  def commentinput(y)
    article_id = 0
    comment_id = 0

    sth1 = @dbh.prepare("SELECT id FROM articles WHERE hnfid = ?")
    sth1.execute(y["hnfid"])
    sth1.fetch do |row|
      article_id = row['id']
    end


    sth2 = @dbh.prepare("INSERT INTO comments (password, date, title, author, url, ipaddr, body) VALUES(?,?,?,?,?,?,?)")
    sth2.execute(y["password"],y["date"],y["title"],y["author"],y["url"],y["ipaddr"],y["body"])
    
    sth3 = @dbh.prepare("SELECT id FROM comments WHERE date = ?")
    sth3.execute(y["date"])
    sth3.fetch do |row|
      comment_id = row['id']
    end

    if article_id == 0
      print "(orphane) #{comment_id}, #{y["article_title"]}\n"
    end

    begin
      sth6 = @dbh.prepare("INSERT INTO comments_articles (comment_id, article_id) VALUES(?,?)")
      sth6.execute(comment_id, article_id)
    rescue
      p $!
    end

  end


end

hdb = Hnfdb.new
hdb.connect
hdb.create_table_pictures
hdb.create_table_articles
#hdb.create_table_ymds
hdb.create_table_comments
hdb.create_table_comments_articles
hdb.create_table_categories
hdb.create_table_categories_articles
#hdb.create_table_dates
#hdb.category_load

def addhnf(hdb,f)
  if f =~ /d(\d{4})(\d{2})(\d{2})\.hnf/
    ymd = $1 + '-' + $2 + '-' + $3
    hnfdate = $1 + $2 + $3

    fftmp = open(f, "r")
    mtime = fftmp.mtime
#    ftmp = fftmp.read.split(/\n/)
    ftmpread = fftmp.read
    
    ftmp = Kconv.toutf8(ftmpread).split(/\n/)
    fftmp.close
    next if ftmp.first != "OK"
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
    t0 = $_
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


ARGV.each do |f|
  if f =~ /d\d{8}.hnf/
    addhnf(hdb,f)
  else
    addcomment(hdb,f)
  end
end



