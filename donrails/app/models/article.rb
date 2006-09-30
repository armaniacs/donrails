require 'uri'
require 'net/http'
include ApplicationHelper

class Article < ActiveRecord::Base
  has_and_belongs_to_many :categories, :join_table => "categories_articles"
  has_many :pings, :order => "id ASC"
  has_many :trackbacks, :order => "id ASC"
  has_many :pictures, :order => "id ASC"
  has_many :comments, :order => "id ASC"
  belongs_to :author
  belongs_to :enrollment
  after_save :sendping
  before_save :renew_mtime
  after_destroy :enrollclean

  # Fulltext searches the body of published articles
  # this function original from "typo" models/article.rb
  def self.search(query)
    if !query.to_s.strip.empty?
      tokens = query.split.collect {|c| "%#{c.downcase}%"}
      find_by_sql(["SELECT * from articles WHERE #{ (["LOWER(body) like ?"] * tokens.size).join(" AND ") } AND (hidden IS NULL or hidden = 0) ORDER by article_date DESC", *tokens])
    else
      []
    end
  end

  def sendping
    if defined?(BASEURL)
      blogping = Blogping.find(:all, :conditions => ["active = 1"])
      if self.enrollment_id
        articleurl = BASEURL + 'id/' + self.enrollment_id.to_s
      else
        articleurl = BASEURL + 'id/' + self.id.to_s
      end
      
      urllist = Array.new
      blogping.each do |ba|
        urllist.push(ba.server_url)
      end
      if urllist.size > 0
        send_pings2(articleurl, urllist)
      end
    end
  end

  def send_pings2(articleurl, urllist)
    urllist.each do |url|
      begin
        ping = pings.build("url" => url)
        ping.send_ping2(url)
        ping.save
      rescue
        p "ping.send_ping2 error"
        p $!
        # in case the remote server doesn't respond or gives an error,
        # we should throw an xmlrpc error here.
      end
    end
  end

  def send_trackback(articleurl, urllist) # urllist is target url.
    urllist.each do |url|
      if url and url.size > 1 # XXX 
        begin
          ping = pings.build("url" => url)
          ar2 = don_get_object(self, 'html')
          title = "#{URI.escape(ar2.title_to_html)}"
          begin
            excerpt = "#{URI.escape(ar2.body_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, ''))}" 
          rescue
            excerpt = ''
          end
          ping.send_trackback(url, title, excerpt)
          ping.save
        rescue
          p "ping.send_ping2 error"
          p $!
          # in case the remote server doesn't respond or gives an error,
          # we should throw an xmlrpc error here.
        end
      end
    end
  end

  def renew_mtime
    self.article_mtime = Time.now
  end

  def enrollclean
    if self.enrollment and self.enrollment.articles.size <= 1
      self.enrollment.destroy
    end
  end

end
