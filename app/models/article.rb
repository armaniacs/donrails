require 'uri'
require 'net/http'
include ApplicationHelper

class Article < ActiveRecord::Base
  validates_presence_of :author_id, :title, :format, :enrollment_id

  has_many :dona_cas
  has_many :categories, :through => :dona_cas

  has_many :dona_daas
  has_many :don_attachments, :through => :dona_daas

  has_many :pictures, :through => :dona_daas, :class_name => "DonAttachment", :conditions => "format = 'picture'", :source => :don_attachment
#  has_many :pictures, :through => :dona_daas, :class_name => "DonAttachment", :conditions => "articles.format = 'picture'", :source => :don_attachment

  has_many :don_pings, :order => "id ASC"
  has_many :trackbacks, :order => "id ASC"
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
    if self.hidden == nil || self.hidden == 0
      if bu = don_get_config.baseurl
        blogping = Blogping.find(:all, :conditions => ["active = 1"])
        baseurl = bu.split('/')
        baseurl << 'notes'
        baseurl << 'id'

        if self.enrollment_id then
          baseurl << self.enrollment_id.to_s
        else
          baseurl << self.id.to_s
        end
        articleurl = baseurl.join('/')
        
        urllist = Array.new
        blogping.each do |ba|
          urllist.push(ba.server_url)
        end
        if urllist.size > 0
          send_pings2(articleurl, urllist)
        end
      end
    end
  end


  def send_pings2(articleurl, urllist)
    urllist.each do |url|
      begin
        ping = don_pings.build("url" => url)
        if don_get_config.ping_async == 1
          logger.info "Async ping queue in"
        else
          ping.send_ping2(url)
          ping.send_at = Time.now
        end
        ping.save
      rescue Exception
        p "DonPing.send_ping2 error"
        # in case the remote server doesn't respond or gives an error,
        # we should throw an xmlrpc error here.
      end
    end
  end

  def send_trackback(articleurl, urllist) # urllist is target url.
    urllist.each do |url|
      if url && url.size > 1 
        begin
          ping = don_pings.build("url" => url)
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
          p "don ping.send_ping2 error"
          p $!
          # in case the remote server doesn't respond or gives an error,
          # we should throw an xmlrpc error here.
        end
      end
    end
  end

  def renew_mtime
    self.article_mtime = Time.now
    if self.article_date == nil
      self.article_date = Time.now
    end
  end

  def enrollclean
    if self.enrollment and self.enrollment.articles.size < 1
      self.enrollment.destroy
    end
  end

end
