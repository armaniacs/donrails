require 'digest/sha1'
require '/usr/share/rails/activerecord/lib/active_record'
require 'yaml'
require 'htree'
require 'cgi'
require 'time'
$KCODE = "UTF8"
require 'kconv'
require 'net/http'
require 'wsse'
require 'rexml/document'
require 'hnfhelper'

fconf = open("#{ENV['HOME']}/.donrails/atomcheck.yml", "r")
conf = YAML::load(fconf)

=begin rdoc

Example of ~/.donrails/atomcheck.yml

* Example1

dbfile: /home/user/.donrails/data.db
adapter: sqlite

* Example2

adapter: postgresql
database: donrails
host: localhost
username: donrailuser
password: donrailpassword

=end

ActiveRecord::Base.establish_connection(conf)

class Article < ActiveRecord::Base
end

class AtomStatus
  def initialize
  end

  def check(target_url, title, body, check=true)
    aris = Article.find(:first, :conditions => ["target_url = ? AND title = ? AND body = ?", target_url, title, body])
    if (aris and aris.status == 201)
      return 0 
    elsif aris
      return aris.id
    else
      aris2 = Article.new("target_url" => target_url, "title" => title, "body" => body)
      aris2.save
      return aris2.id
    end
  end

  def update(id, status, check=true)
    if check
      aris = Article.find(id)
      aris.status = status
      aris.save
    end
  end
end

class AtomPost
  def initialize
  end

  def atompost(target_url, user, pass, 
               title, body, article_date, 
               category, format, check=true, 
               preescape=true, content_mode=nil, relateid=nil)

    as = AtomStatus.new
    id = as.check(target_url, title, body, check)
    if check
      if id == 0
        print "Already posted\n"
        return false
      end
    end

    postbody = "<entry xmlns='http://www.w3.org/2005/Atom'>\n"
    article_date = Time.now.iso8601 unless article_date
    postbody += "<articledate>#{article_date}</articledate>\n"
    postbody += "<relateid>#{relateid}</relateid>\n" if relateid
    p relateid if relateid

    if category
      category.each do |cate|
        postbody += "<category term='#{cate}'/>\n"
      end
    end
    if format == 'hnf'
      title = HNFHelper.new.title_to_html(title) if title
      body = HNFHelper.new.body_to_html2(body, preescape) if body
    end

    postbody += "<title>#{title}</title>\n" if title

    # XXX
    if body =~/<html.+<\/html>/m
      bx = HTree.parse(body).to_rexml
      if bx.root.elements['body'].to_s =~ /<body>(.*)<\/body>/m
        body = $1
      else 
        body = bx.root.elements['body'].to_s.sub(/^<body \w+='.+'/, "<body")
        if body =~ /<body>(.*)<\/body>/m
          body = $1
        end
#        content_mode = 'escaped'
      end
    end

    if body
      if content_mode == 'escaped'
        postbody += "<content type='text/html' mode='escaped'>" + CGI.escapeHTML(CGI.unescapeHTML(body)) + '</content>'
      elsif content_mode == 'plain'
        postbody += "<content type='text/plain' mode='escaped'>" + CGI.escapeHTML(CGI.unescapeHTML(body)) + '</content>'
      elsif content_mode == 'base64'
        postbody += "<content type='#{format}' mode='base64'>" + body + '</content>'
      else
        postbody += "<content type='text/html'>#{body}</content>" 
      end
    end
    postbody += "</entry>"

    xml = HTree.parse(postbody).to_rexml
    postbody = xml.root.to_s

    url = URI.parse(target_url)
    req = Net::HTTP::Post.new(url.path)

    req['X-WSSE'] = WSSE.new.generate(user, pass)
    req['host'] = url.host
    req['Content-Type']= 'application/atom+xml'
    begin
      res = Net::HTTP.new(url.host, url.port).start {|http|
        http.request(req, postbody)
      }
    rescue Errno::ECONNREFUSED
      print "#{target_url} is not alive. Connection refused.\n"
      raise Errno::ECONNREFUSED
    end

    case res
    when Net::HTTPCreated 
      p "Success, #{article_date}"
      as.update(id, 201,check)
      return res
    when Net::HTTPRedirection
      p "Redirect to #{res['location']}"
      atompost(res['location'], user, pass, title, body, article_date, category, format, check, preescape, content_mode)
    else
      p "Error, #{article_date}"
      p res
      res.error!
      as.update(id, -1)
      return res
    end
  end

  def addguess(target_url, user, pass, f, check=true, preescape=true, content_mode=nil)
    fftmp = open(f, "r")
    mtime = fftmp.mtime
    ftmpread = fftmp.read
    fftmp.close
    content = Kconv.toutf8(ftmpread)
    ftmp = content.split(/\n/)

    if ftmp.first =~ /^OK$/
      addhnf(target_url, user, pass, f, check, preescape, content_mode)
    elsif ftmp.first =~ /<html>/i and ftmp.last =~ /<\/html>/i
      addhtml(target_url, user, pass, f, check, preescape, content_mode)
    else
      print "unsupported type\n"
    end
  end

  def addhtml(target_url, user, pass, f=nil, check=true, preescape=true, content_mode=nil, data=nil)
    if data
      ftmpread = data
      mtime = Time.now
    elsif f
      fftmp = open(f, "r")
      mtime = fftmp.mtime
      ftmpread = fftmp.read
      fftmp.close
    else
      return false
    end
    ftmp = Kconv.toutf8(ftmpread)
    title = ''
    body = ''

    xml = HTree.parse(ftmp).to_rexml
    title = xml.root.elements['head/title'].to_s 
    body = xml.root.elements['body'].to_s
    article_date = mtime.iso8601

    atompost(target_url, user, pass, title, body, article_date, nil, 'html', check, preescape, content_mode)
  end

  def addhnf(target_url, user, pass, f=nil, check=true, preescape=true, content_mode=nil, data=nil)
    if f =~ /d(\d{4})(\d{2})(\d{2})\.hnf/
      ymd = $1 + '-' + $2 + '-' + $3
      hnfdate = $1 + $2 + $3
      fftmp = open(f, "r")
      mtime = fftmp.mtime
      data = fftmp.read 
      fftmp.close
    elsif data
      mtime = Time.now
      if mtime.iso8601 =~ /^(\d{4})-(\d{2})-(\d{2})/
        ymd = $1 + '-' + $2 + '-' + $3
        hnfdate = $1 + $2 + $3
      end
    end

    ftmp = Kconv.toutf8(data).split(/\n/)
    ftmp.shift

    y = Hash.new
    if ymd
      y['ymd'] = ymd
    else
      y['ymd'] = mtime
    end
    y['mtime'] = mtime
    y['text'] = ''
    daynum = 0

    ftmp.each do |x|
      if x =~ /^(CAT|NEW|LNEW)\s+.+/
        if y['title']
          atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'], 'hnf', check, preescape, content_mode)
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
    atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'], 'hnf', check, preescape, content_mode)
  end

end
