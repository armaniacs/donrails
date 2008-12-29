# -*- coding: utf-8 -*-
## TODO: migrate classic_pagination to will_pagenate

require 'kconv'
class NotesController < ApplicationController

  include Akismet

  class << self
    include ApplicationHelper
  end
      
  before_filter :set_charset, :except => [
    :pick_article_a, :pick_article_a2, :comment_form_a,
    :recent_category_title_a, :recent_trigger_title_a, :category_select_a,
    :category_tree_list_a
  ]

  cache_sweeper :article_sweeper, :only => [:add_comment2, :trackback]

  caches_page :index, :show_month, :show_nnen, :show_date, :show_category, :show_category_noteslist, :articles_long, :noteslist, :category_select_a, :recent_trigger_title_a, :recent_category_title_a, :category_tree_list_a, :articles_author, :sitemap, :show_enrollment

  after_filter :add_cache_control
  after_filter :compress
  after_filter :clean_memory

  layout don_get_theme("notes"), :except => [
    :pick_article_a,
    :pick_article_a2,
    :recent_category_title_a,
    :recent_trigger_title_a,
    :trackback,
    :pick_trackback_a,
    :catch_ping,
    :catch_trackback,
    :category_select_a,
    :comment_form_a,
    :comment_form,
    :pick_comment_a,
    :category_tree_list_a,
    :sitemap,
    :pick_enrollment_a                             
  ]

  def index
    @heading = "index"
    recent
  end

  def search
    @articles = Article.search(params["q"])
    @heading = params["q"]
    @noindex = true
    @lm = Time.now.gmtime
  end

  def show_search_noteslist
    search
    @rdf_category = params['q']
    @heading = "検索結果:#{params['q']}"
    render :action => don_get_theme('noteslist')
  end

  def pick_trackback_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @trackback = Trackback.find(params['pickid'].to_i)
  end

  def pick_comment_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @comment = Comment.find(params['pickid'].to_i)
  end

  def pick_enrollment_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @enrollment = Enrollment.find(params['pickid'].to_i)
    @lm = @enrollment.updated_at.gmtime if @enrollment and @enrollment.updated_at
  end

  def pick_article_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(params['pickid'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def pick_article_a2
    headers["Content-Type"] = "text/html; charset=utf-8"
    if params[:pickid]
      @article = Article.find(params['pickid'].to_i)
      @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
    elsif params[:eid]
      enrollment = Enrollment.find(params[:eid], :conditions => ["hidden IS NULL OR hidden = 0"])
      @article = enrollment.articles.first
    end

  end

  def comment_form_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(params['id'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def comment_form
    @noindex = true
    @article = Article.find(params['id'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def articles_long
    @articles = Article.paginate(:page => params[:page], :per_page => 10,
                                          :order => 'size DESC, id DESC',
					  :conditions => ["hidden IS NULL OR hidden = 0"]
                                          )

    @heading = "記事サイズ順の表示"
    @noindex = true
    unless @articles.empty? then
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end
    render :action => don_get_theme('noteslist')
  end

  def articles_author
    begin
      @articles = Article.paginate(:page => params[:page], :per_page => 10,
                                            :order => 'id DESC',
                                            :conditions => ["author_id = ? AND ( hidden IS NULL OR hidden = 0 )", params['id']]
                                            )
      @author = Author.find(params['id'])
      if @author
        if @author.nickname
          @heading = @author.nickname + "の記事"
        else
          @heading = @author.name + "の記事"
        end
        unless @articles.empty? then
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
        render :action => don_get_theme('noteslist')
      end
    rescue
      render :text => 'no entry', :status => 404
    end
  end

  def indexabc
    k = params['nums']
    if k =~ /^(\d\d\d\d)(\d\d)a(\.html)?$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
    elsif k =~ /^(\d\d\d\d)(\d\d)b(\.html)?$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
    elsif k =~ /^(\d\d\d\d)(\d\d)c(\.html)?$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
    else
      render :text => 'no entry', :status => 404
    end
  end

  def noteslist
    minTime = nil
    flash.keep if flash[:notice]

    @articles = Article.paginate(:page => params[:page], :order => 'article_date DESC, id DESC', :conditions => ["hidden IS NULL OR hidden = 0"])

    unless @articles.empty?
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    else
      de = DonEnv.find(:first, :conditions => ["hidden IS NULL OR hidden = 0"])
      if de == nil
        flash[:notice] = 'first setup'
        redirect_to :controller => 'admin/system', :action => 'manage_don_env'
        return
      end
    end

    if minTime and @lm <= minTime
      # use cached version
      render :text => '304 Not Modified', :status => 304
    else
      if @articles.empty? then
        @heading = ""
      else
        a = don_get_object(@articles.first, 'html')
        @heading = "#{don_chomp_tags(a.title_to_html)} at #{@articles.first.article_date.to_date}"
      end
      flash[:notice] = params['notice'] unless flash[:notice]
    end
    render :action => don_get_theme('noteslist')
  end


  def parse_nums
    nums = params['nums'] if params['nums'] 

    flash[:notice] = nums
    if nums =~ /^(\d\d\d\d)(\d\d)(\d\d)$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    elsif nums =~ /^(\d+)-(\d+)-(\d+)$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    elsif nums =~  /^(\d\d\d\d)-?(\d\d)-?(\d\d)\.html?$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    else
      flash[:notice] = "正しく日付を指定してください" unless flash[:notice]
      redirect_to :action => 'noteslist', :notice => flash[:notice]
    end
  end

  def recent
    @recent_articles = Article.find(:all, :order => "article_mtime DESC", 
                                    :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"],
                                    :limit => 10)
    unless @recent_articles.empty? then
      @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
    end

    @recent_comments = Article.find_by_sql(["SELECT articles.* FROM articles,comments WHERE (articles.hidden IS NULL OR articles.hidden = 0) AND (comments.article_id=articles.id) ORDER BY comments.date DESC limit 10"])

    @recent_trackbacks = Article.find_by_sql(["SELECT articles.* FROM articles,trackbacks WHERE (articles.hidden IS NULL OR articles.hidden = 0) AND (trackbacks.article_id=articles.id) ORDER BY trackbacks.created_at DESC limit 10"])

    @long_articles = Article.find(:all, :order => "size DESC", :limit => 10,
                                  :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
  end
  private :recent

  def recent_category(category)
    categories = Category.find(:first, :conditions => ["name = ?", category])

    return [] if categories.nil?
    articles = categories.articles
    return articles.reverse!
  end
  private :recent_category


  def recent_trigger_title_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    if params['trigger'] == 'recents'
      @articles = Article.find(:all, :order => "id DESC", :limit => 10, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif params['trigger'] == 'trackbacks'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN trackbacks on (trackbacks.article_id=articles.id)", :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif params['trigger'] == 'comments'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN comments on (comments.article_id=articles.id)", :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif params['trigger'] == 'long'
      @articles = Article.find(:all, :order => "size DESC", :limit => 10, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    end
    if @articles
      unless @articles.empty? then
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
    end
  end

  # if request.post? is true, cache_page does not work.
  def recent_category_title_a
    headers["Content-Type"] = "text/html; charset=utf-8"

    if params['category']
      categories = Category.find(:first, :conditions => ["name = ?", params['category']])
      return [] if categories.nil?
      @articles = categories.articles.reverse
      unless @articles.empty? then
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime 
      end
    end
  end

  def category_select_a 
    headers["Content-Type"] = "text/html; charset=utf-8"
    @categories = Category.find(:all)
  end

  def category_tree_list_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    expires_in 72.hours, 'max-stale' => 120.hours, :private => nil, :public => true
    @roots = Category.find(:all, :conditions => ["parent_id IS NULL"])
  end

  def show_month
    begin
      get_ymd
      if @ymd and @ymd31a
        @articles =  Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd31a])

        if @articles and @articles.empty? then
          render :text => "no article", :status => 404
        else
          @heading = "#{@articles.first.article_date.to_date} - #{@articles.last.article_date.to_date}"
          @noindex = true
          unless @articles.empty?
            @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
          end
          render :action => don_get_theme('noteslist')
        end
      else
        render :text => "no article", :status => 404
      end
      
    rescue
      logger.info $!
      render :text => "no article", :status => 404
    end
  end

  def show_nnen
    if (params["day"] and params["month"])
      ymdnow = convert_ymd("#{Time.now.year}-#{params["month"]}-#{params["day"]}")
    else
      render :text => "no article", :status => 404
    end
    if ymdnow =~ /(\d\d\d\d)-(\d\d)-(\d\d)/
      t2 = Time.local($1,$2,$3)
    end
    t3 = t2
    @articles = Article.find(:all, :order => "id DESC", :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", t2, t2.tomorrow])

    for i in 1..10
      t2 = t2.last_year
      i += 1
      @articles += Article.find(:all, :order => "id DESC", :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", t2, t2.tomorrow])
    end
    unless @articles.empty? then
      flash[:notice] = "#{t2.month}月 #{t2.day}日の記事(#{@articles.first.article_date.year}年から#{@articles.last.article_date.year}年まで)"
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end
    @noindex = true

    if @articles.empty?
      render :text => "no article", :status => 404
    else
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      render :action => don_get_theme('noteslist')
    end
  end

  def show_date
    get_ymd
    if @ymd
      @articles = Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd1a])
    else
      flash[:notice] = "正しく日付を指定してください" unless flash[:notice]
      redirect_to :action => 'noteslist', :notice => flash[:notice]
    end

    begin
      a = don_get_object(@articles.first, 'html')
      @heading = "#{don_chomp_tags(a.title_to_html)} at #{@articles.first.article_date.to_date}"
      unless @articles.empty?
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
      render :action => don_get_theme('noteslist')
    rescue
      logger.info $!
      flash[:notice] = "正しく日付を指定してください" unless flash[:notice]
      redirect_to :action => 'noteslist', :notice => flash[:notice]
    end
  end

  def show_title
    @noindex = true
    if params['id']
      @articles =  Article.find(:all, :conditions => ["id = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", params['id']]) 
    elsif params['pickid']
      @articles =  Article.find(:all, :conditions => ["id = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", params['pickid']]) 
      redirect_to :action => 'show_title', :id => @articles.first.id if @articles
      return
    elsif params['title'] and params['title'].size > 0
      @articles =  Article.find(:all, :conditions => ["title = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", params['title']]) 
      redirect_to :action => 'show_title', :id => @articles.first.id if @articles and @articles.first
      return
    else
      render :text => "no article", :status => 404
      return
    end

    if @articles
      unless @articles.empty?
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
    end
    if @articles and @articles.size >= 1
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      a = don_get_object(@articles.first, 'html')
      @heading = don_chomp_tags(a.title_to_html)
      cid = @articles.first.id
      @rdf_article = @articles.first.id
      begin
        @lastarticle = Article.find(cid - 1, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      rescue
      end
      begin
        @nextarticle = Article.find(:first, :conditions => ["id > ? AND (articles.hidden IS NULL OR articles.hidden = 0)", cid])
      rescue
      end
    else
      begin
        a1 = Article.find(params['id'])
        redirect_to :action => 'show_enrollment', :id => a1.enrollment_id
        return
      rescue
        render :text => "no article", :status => 404
        return
      end
    end
    render :action => don_get_theme("show_title")
  end

  def show_enrollment
    if pid = params['id'].to_i
      @enrollment = Enrollment.find(pid, :conditions => ["hidden IS NULL OR hidden = 0"])
      @heading = "#{don_chomp_tags(don_get_object(@enrollment.articles.first, 'html').title_to_html)}"
      @rdf_enrollment = @enrollment.id
      begin
        @enrollment_l = Enrollment.find_by_sql(["SELECT id FROM enrollments WHERE (hidden IS NULL OR hidden = 0) AND ID < ? ORDER BY ID DESC LIMIT 1", pid]).first
      rescue
        @enrollment_l = nil
      end
      begin
        @enrollment_r = Enrollment.find_by_sql(["SELECT id FROM enrollments WHERE (hidden IS NULL OR hidden = 0) AND ID > ? ORDER BY ID LIMIT 1", pid]).first
      rescue
        @enrollment_r = nil
      end
    end
    render :action => don_get_theme("show_enrollment")
  end

  def show_category_core
    begin
      if params[:id]
        @category = Category.find(params[:id])
      elsif cp = params['category']
        cp.sub!(/\.html$/, '')
        @category = Category.find(:first, :conditions => ["name = ?", params['category']])
      elsif params['nocategory']
        @category = Category.find(:first, :conditions => ["NOT name = ?", params['nocategory']])
      end

      if @category and @category.id
        ccs = collect_category_ids(@category)
        @articles = Array.new
        ccs.each do |cid|
          @articles = @articles | Article.paginate(:page => params[:page],
                                       :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"],
                                       :joins => "JOIN dona_cas on (dona_cas.article_id=articles.id AND dona_cas.category_id=#{cid})",
                                       :order => 'articles.article_date DESC'
                                       )
        end
        @articles = @articles.sort.reverse
        @heading = "カテゴリ:#{params['category']}"
        @heading += '(' + @category.articles.size.to_s + ')'

        unless @articles.empty? then
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
      end
    rescue
      logger.info $!
    end
  end

  def show_category
    show_category_core
    if @articles && @category && @category.name
      render :action => "show_category"
    else
      render :text => "no article", :status => 404
    end
  end

  def show_category_noteslist
    begin
      show_category_core
      if @articles
        render :action => don_get_theme('noteslist')
      else
        render :text => "no article", :status => 404
      end
    rescue
      logger.info $!
      render :text => "no article", :status => 404
    end
  end

  def afterday
    @noindex = true
    get_ymd
    if @ymd
      @articles =  Article.find(:all, :limit => 30,
                                :conditions => ["article_date >= ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd])
      if @articles.first
        a = don_get_object(@articles.first, 'html')
        @heading = don_chomp_tags(a.title_to_html)
        flash[:notice] = "#{@articles.first.article_date.to_date} 以降 30件の記事を表示します。"
        unless @articles.empty?
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
        render :action => don_get_theme('noteslist')
      else
        render :text => "#{@ymd}以降に該当する記事はありません", :status => 404
      end
    else
      render :text => "please select only one day", :status => 404
    end
  end

  def tendays
    get_ymd
    @noindex = true
    @articles = Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd10a])
    if @articles.size > 0
      unless @articles.empty?
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
      a = don_get_object(@articles.first, 'html')
      @heading = don_chomp_tags(a.title_to_html)
    
      flash[:notice] = "#{@articles.first.article_date.to_date} 以降の10日間の記事を表示します。"
      render :action => don_get_theme('noteslist')
    else
      flash[:notice] = "正しく日付を指定してください" unless flash[:notice]
      render :text => "#{@ymd}以降に該当する記事はありません", :status => 404
    end
  end

  def add_comment2
    c = params["comment"]
    if c and request.post?
      author = c["author"]
      password = c["password"]
      url = c["url"]
      title = c["title"]
      body = c["body"]
      article_id = c["article_id"].to_i

      a = Article.find(article_id, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      aris1 = Comment.new("password" => password,
                          "date" => Time.now,
                          "title" => title,
                          "author" => author,
                          "url" => url,
                          "ipaddr" => request.remote_ip,
                          "body" => body,
                          "article_id" => a.id
                          )
      akq = {
        :comment_content => aris1.body,
        :comment_author_url => aris1.url,
        :comment_author => aris1.title,
        :title => aris1.title,
        :body => aris1.body,
        :url => aris1.url,
        :ip => aris1.ipaddr
      }
      if don_is_spam?(akq)
        aris1.hidden = 1
        aris1.spam = 1
      end

      if @catched == false
        aris1.save
        render :text => @message, :status => 403
        return
      end

      aris1.valid?
      if aris1.errors.empty?
        aris1.save
        if a.enrollment_id
          redirect_to :action => "show_enrollment", :id => a.enrollment_id
        else
          redirect_to :action => "noteslist"
        end
      else
         emg = ''
         aris1.errors.each_full do |msg|
           emg += msg + "\n"
         end
         render :text => emg, :status => 403
      end
    else
      redirect_to :action => "noteslist"
    end
  end

  def picture_get
    @picture = Picture.new
  end

  def show_image 
    if @image = Picture.find(params['id'].to_i)
      if @image.hidden == 1
        render :text => 'image hidden', :status => 403
      else
        redirect_to '/' + @image.path.split(%r!(?:^|/)public/!).last
      end
    end
  end

  def trackback
    if request.method == :post
      begin
        unless (params.has_key?('url') and params.has_key?('id'))
          @catched = false
          @message = 'need url and id '
        end

        begin
          article = Article.find(params['id'], :conditions => ["hidden IS NULL OR hidden = 0"])
        rescue
          @catched = false
          @message = 'need valid id '
        end

        if @catched != false
          tb = Trackback.new
          tb.article_id = article.id
          tb.category = params['category'] if params['category'] 
          tb.blog_name = params['blog_name'] if params['blog_name']
          tb.title = params['title'] || params['url']
          tb.excerpt = params['excerpt'] if params['excerpt']
          tb.url = params['url']
          tb.ip = request.remote_ip
          tb.created_at = Time.now

          akq = {
            :comment_content => tb.excerpt,
            :comment_author_url => tb.url,
            :comment_author => tb.title,
            :blog_name => tb.blog_name,
            :title => tb.title,
            :excerpt => tb.excerpt,
            :url => tb.url,
            :ip => tb.ip
          }
          if don_is_spam?(akq)
            tb.hidden = 1
            tb.spam = 1
          end

          tb.save

          if tb.errors.empty?
            @catched = true if @catched == nil
            @message = 'success' if @message == nil
          else
            @catched = false
            @message = 'count:' + tb.errors.count.to_s if @message == nil
          end
        end
      rescue
        @message = $!
        @catched = false
      end
    else
      @catched = false
      @message = 'Please use HTTP POST'
    end

    if @catched == false
      render :status => 403
      return
    end
  end

  def catch_trackback
    headers["Content-Type"] = "text/xml; charset=utf-8"
    if request.method == :post
      category = params['category'] if params['category'] 
      blog_name = params['blog_name'] if params['blog_name']
      title = params['title'] || params['url']
      excerpt = params['excerpt'] if params['excerpt']
      url = params['url']
      
      ip = request.remote_ip
      created_at = Time.now
      @catched = true
    else
      @catched = false
    end
  end

  def catch_ping
    headers["Content-Type"] = "text/xml; charset=utf-8"
    if request.method == :post
      @catched = true
    else
      @catched = false
    end
  end

  def sitemap
    @articles = Article.find(:all, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"], :order => 'article_mtime DESC') 
  end

  protected
  def authenticate
    unless session["person"]
      redirect_to :controller => "login", :action => "login_index"
      return false
    end
  end

  def add_cache_control
    if @lm
      headers['Last-Modified'] = @lm.httpdate.to_s
    end
    if @maxage and @maxage == 0
      headers['Cache-Control'] = 'no-cache'
    elsif @maxage
      headers['Cache-Control'] = 'max-age=#{@maxage.to_s}'
    elsif @lm and @noindex and Time.now - @lm < 86400 * 7
      headers['Cache-Control'] = 'max-age=86400'
    elsif @lm and Time.now - @lm < 86400 * 7
      headers['Cache-Control'] = 'no-cache'
    else
      headers['Cache-Control'] = 'public'
    end
  end

end
