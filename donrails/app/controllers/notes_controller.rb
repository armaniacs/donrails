require 'kconv'
class NotesController < ApplicationController

  before_filter :set_charset, :except => [
    :pick_article_a, :pick_article_a2, :comment_form_a,
    :recent_category_title_a, :recent_trigger_title_a, :category_select_a,
    :category_tree_list_a
  ]

  cache_sweeper :article_sweeper, :only => [:add_comment2, :trackback]
  verify_form_posts_have_security_token :only => [:add_comment2]

  caches_page :index, :rdf_recent, :rdf_article, :rdf_category, :show_month, :show_nnen, :show_date, :show_title, :show_category, :show_category_noteslist, :articles_long, :noteslist

  caches_page :category_select_a, :recent_trigger_title_a, :recent_category_title_a, :category_tree_list_a
  caches_page :articles_author, :sitemap
  after_filter :add_cache_control
  after_filter :compress
  after_filter :clean_memory

  layout "notes", :except => [
    :pick_article_a,
    :pick_article_a2,
    :recent_category_title_a,
    :recent_trigger_title_a,
    :rdf_recent,
    :rdf_article,
    :rdf_search,
    :rdf_category,
    :trackback,
    :pick_trackback_a,
    :catch_ping,
    :catch_trackback,
    :category_select_a,
    :comment_form_a,
    :comment_form,
    :pick_comment_a,
    :category_tree_list_a,
    :sitemap                             
  ]

  def index
    dateparse
    recent
    @heading = "index"
  end

  def search
    @articles = Article.search(@params["q"])
    @heading = @params["q"]
    @noindex = true
    @lm = Time.now.gmtime
  end

  def show_search_noteslist
    search
    @rdf_category = @params['q']
    @heading = "検索結果:#{@params['q']}"
    render_action 'noteslist'
  end

  def pick_trackback_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @trackback = Trackback.find(@params['pickid'].to_i)
  end

  def pick_comment_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @comment = Comment.find(@params['pickid'].to_i)
  end

  def pick_article_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(@params['pickid'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def pick_article_a2
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(@params['pickid'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def comment_form_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(@params['id'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def comment_form
    @article = Article.find(@params['id'].to_i)
    @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
  end

  def articles_long
    @articles_pages, @articles = paginate(:article, :per_page => 10,
                                          :order_by => 'size DESC, id DESC',
					  :conditions => ["hidden IS NULL OR hidden = 0"]
                                          )
    @heading = "記事サイズ順の表示"
    @noindex = true
    unless @articles.empty? then
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end
    render_action 'noteslist'
  end

  def articles_author
    begin
      @articles_pages, @articles = paginate(:article, :per_page => 10,
                                            :order_by => 'id DESC',
                                            :conditions => ["author_id = ? AND ( hidden IS NULL OR hidden = 0 )", @params['id']]
                                            )
      @author = Author.find(@params['id'])
      if @author
        if @author.nickname
          @heading = @author.nickname + "の記事"
        else
          @heading = @author.name + "の記事"
        end
        unless @articles.empty? then
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
        render_action 'noteslist'
      end
    rescue
      render :text => 'no entry', :status => 404
    end
  end

  def indexabc
    k = @params['nums']
    if k =~ /^(\d\d\d\d)(\d\d)a$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
    elsif k =~ /^(\d\d\d\d)(\d\d)b$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
    elsif k =~ /^(\d\d\d\d)(\d\d)c$/
      redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
    else
      render :text => 'no entry', :status => 404
    end
  end

  def dateparse
    @params.keys.each do |k|
      if k =~ /(\d\d\d\d)(\d\d)a/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
      elsif k =~ /(\d\d\d\d)(\d\d)b/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
      elsif k =~ /(\d\d\d\d)(\d\d)c/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
      elsif k =~ /([01]\d)([0-3]\d)/
        redirect_to :action => "show_nnen", :month => $1, :day => $2
      end
    end
  end

  def noteslist
#    minTime = Time.rfc2822(@request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
    minTime = nil
    @articles_pages, 
    @articles = paginate(:article, :per_page => 30,
                         :order_by => 'article_date DESC, id DESC',
			 :conditions => ["hidden IS NULL OR hidden = 0"]
                         )
    unless @articles.empty?
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end

    if minTime and @lm <= minTime
      # use cached version
      render_text '', '304 Not Modified'
    else
      if @articles.empty? then
        @heading = ""
      else
        a = don_get_object(@articles.first, 'html')
        @heading = "#{don_chomp_tags(a.title_to_html)} at #{@articles.first.article_date.to_date}"
      end
      @notice = @params['notice'] unless @notice
    end
  end


  def parse_nums
    nums = @params['nums'] if @params['nums'] 

    @notice = nums
    if nums =~ /^(\d\d\d\d)(\d\d)(\d\d)$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    elsif nums =~ /^(\d+)-(\d+)-(\d+)$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    elsif nums =~  /^(\d\d\d\d)-?(\d\d)-?(\d\d)\.html?$/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    else
      @notice = "正しく日付を指定してください" unless @notice
      redirect_to :action => 'noteslist', :notice => @notice
    end
  end

  def rdf_recent
    @headers["Content-Type"] = "application/xml; charset=utf-8"
    @recent_articles = Article.find(:all, :order => "article_mtime DESC", :limit => 20, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    unless @recent_articles.empty? then
      @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
    end
  end

  def rdf_article
    if @params['id'] and @article = Article.find(@params['id'], :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      @rdf_article = @article.id
      @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
      @headers["Content-Type"] = "application/xml; charset=utf-8"
    else
      render :text => "no entry", :status => 404
    end
  end

  def rdf_search
    @headers["Content-Type"] = "application/xml; charset=utf-8"
    @lm = Time.now.gmtime
    @recent_articles = Article.search(@params["q"])
    @rdf_search = @params["q"]
    if @recent_articles == nil
      render_text "no entry"
    end
  end

  def rdf_category
    @headers["Content-Type"] = "application/xml; charset=utf-8"
    @category = Category.find(:first, :conditions => ["name = ?", @params['category']])
    if @category == nil
      @params["q"] = @params["category"]
      redirect_to :action => 'rdf_search', :q => @params["category"]
    else
      @recent_articles_pages, 
      @recent_articles = paginate(:article, :per_page => 20,
                                  :order_by => 'id DESC',
                                  :join => "JOIN categories_articles on (categories_articles.article_id=articles.id and categories_articles.category_id=#{@category.id})",
                                  :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"]
                                  )
      @rdf_category = @category.name
      unless @recent_articles.empty? then
        @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
      end
    end
  end

  def recent
    @recent_articles = Article.find(:all, :order => "id DESC", 
                                    :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"],
                                    :limit => 10)
    unless @recent_articles.empty? then
      @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
    end
    @recent_comments = Article.find(:all, :order => "articles.article_date DESC", :limit => 30,
                                    :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"],
                                    :joins => "JOIN comments_articles on (comments_articles.article_id=articles.id)"
                                   )

    @rt = Article.find(:all, 
                       :order => "articles.article_date DESC", 
                       :limit => 30,
                       :joins => "JOIN trackbacks on (trackbacks.article_id=articles.id)",
                       :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"]
                       )
    aid = Array.new
    @rt.each do |rt|
      aid.push rt.article_id
    end
    @recent_trackbacks = Article.find(aid, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
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
    @headers["Content-Type"] = "text/html; charset=utf-8"
    if @params['trigger'] == 'recents'
      @articles = Article.find(:all, :order => "id DESC", :limit => 10, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif @params['trigger'] == 'trackbacks'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN trackbacks on (trackbacks.article_id=articles.id)", :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif @params['trigger'] == 'comments'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN comments_articles on (comments_articles.article_id=articles.id)", :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    elsif @params['trigger'] == 'long'
      @articles = Article.find(:all, :order => "size DESC", :limit => 10, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    end
    unless @articles.empty? then
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end
  end

  # if @request.post? is true, cache_page does not work.
  def recent_category_title_a
    @headers["Content-Type"] = "text/html; charset=utf-8"

    if @params['category']
      categories = Category.find(:first, :conditions => ["name = ?", @params['category']])
      return [] if categories.nil?
      @articles = categories.articles.reverse
      unless @articles.empty? then
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime 
      end
    end
  end

  def category_select_a 
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @categories = Category.find_all
  end

  def category_tree_list_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    expires_in 72.hours, 'max-stale' => 120.hours, :private => nil, :public => true
    @roots = Category.find(:all, :conditions => ["parent_id IS NULL"])
  end

  def show_month
    begin
      get_ymd
      if @ymd and @ymd31a
        @articles =  Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd31a])
      else
        render_text "no article", 404
      end
      if @articles and @articles.empty? then
        render_text "no article", 404
      else
        @heading = "#{@articles.first.article_date.to_date} - #{@articles.last.article_date.to_date}"
        @noindex = true
        unless @articles.empty?
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
        render_action 'noteslist'
      end
    rescue
      render_text "no article", 404
    end
  end

  def show_nnen
    if (@params["day"] and @params["month"])
      ymdnow = convert_ymd("#{Time.now.year}-#{@params["month"]}-#{@params["day"]}")
    else
      render_text "no article", 404
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
      @notice = "#{t2.month}月 #{t2.day}日の記事(#{@articles.first.article_date.year}年から#{@articles.last.article_date.year}年まで)"
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
    end
    @noindex = true
    if @articles.empty?
      render_text "no article", 404
    else
      @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      render_action 'noteslist'
    end
  end

  def show_date
    get_ymd
    if @ymd
      @articles = Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd1a])
    else
      @notice = "正しく日付を指定してください" unless @notice
      redirect_to :action => 'noteslist', :notice => @notice
    end

    begin
      a = don_get_object(@articles.first, 'html')
      @heading = "#{don_chomp_tags(a.title_to_html)} at #{@articles.first.article_date.to_date}"
      unless @articles.empty?
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
      render_action 'noteslist'
    rescue
      @notice = "正しく日付を指定してください" unless @notice
      redirect_to :action => 'noteslist', :notice => @notice
    end
  end

  def show_title
    if @params['id']
      @articles =  Article.find(:all, :conditions => ["id = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @params['id']]) 
    elsif @params['pickid']
      @articles =  Article.find(:all, :conditions => ["id = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @params['pickid']]) 
      redirect_to :action => 'show_title', :id => @articles.first.id if @articles
    elsif @params['title'] and @params['title'].size > 0
      @articles =  Article.find(:all, :conditions => ["title = ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @params['title']]) 
      redirect_to :action => 'show_title', :id => @articles.first.id if @articles and @articles.first
    else
      render_text "no article", 404
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
      render_text "no article", 404
    end
  end

  def show_category
    if @params[:id]
      @category = Category.find(@params[:id])
    elsif @params['category']
      @category = Category.find(:first, :conditions => ["name = ?", @params['category']])
    elsif @params['nocategory']
      @category = Category.find(:first, :conditions => ["NOT name = ?", @params['nocategory']])
    end

    if @category and @category.id
      @articles_pages, @articles = 
        paginate(:article, 
                 :order_by => 'articles.article_date DESC',
                 :per_page => 30, 
                 :join => "JOIN categories_articles on (categories_articles.article_id=articles.id and categories_articles.category_id=#{@category.id})",
		 :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"]
                 )
      @heading = "カテゴリ:#{@params['category']}"
      @heading += '(' + @category.articles.size.to_s + ')'

      unless @articles.empty? then
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
    else
      render_text "no article", 404
    end
  end

  def show_category_noteslist
    begin
      show_category
      @rdf_category = @params['category']
      render_action 'noteslist'
    rescue
      render_text "no article", 404
    end
  end

  def afterday
    @noindex = true
    @debug_oneday = @request.request_uri
    get_ymd
    if @ymd
      @articles =  Article.find(:all, :limit => 30,
                                :conditions => ["article_date >= ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd])
      if @articles.first
        a = don_get_object(@articles.first, 'html')
        @heading = don_chomp_tags(a.title_to_html)
        @notice = "#{@articles.first.article_date.to_date} 以降 30件の記事を表示します。"
        unless @articles.empty?
          @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
        end
        render_action 'noteslist'
      else
        render_text "#{@ymd}以降に該当する記事はありません", 404
      end
    else
      render_text "please select only one day", 404
    end
  end

  def tendays
    @debug_oneday = @request.request_uri
    get_ymd
    @noindex = true
    @articles = Article.find(:all, :conditions => ["article_date >= ? AND article_date < ? AND (articles.hidden IS NULL OR articles.hidden = 0)", @ymd, @ymd10a])
    if @articles.size > 0
      unless @articles.empty?
        @lm = @articles.first.article_mtime.gmtime if @articles.first.article_mtime
      end
      a = don_get_object(@articles.first, 'html')
      @heading = don_chomp_tags(a.title_to_html)
    
      @notice = "#{@articles.first.article_date.to_date} 以降の10日間の記事を表示します。"
      render_action 'noteslist'
    else
      @notice = "正しく日付を指定してください" unless @notice
      render_text "#{@ymd}以降に該当する記事はありません", 404
    end
  end

  def add_comment2
    c = @params["comment"]
    if c and request.post?
      author = c["author"]
      password = c["password"]
      url = c["url"]
      title = c["title"]
      body = c["body"]
      article_id = c["article_id"].to_i

      aris1 = Comment.new("password" => password,
                          "date" => Time.now,
                          "title" => title,
                          "author" => author,
                          "url" => url,
                          "ipaddr" => @request.remote_ip,
                          "body" => body
                          )
      a = Article.find(article_id, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      aris1.articles.push_with_attributes(a)

      aris1.valid?
      if aris1.errors.empty?
        aris1.save
        redirect_to :action => "show_title", :id => article_id, :post_at => Time.now.to_i
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
    @image = Picture.find(@params['id'])
    if @image.hidden == 1
      render :text => 'image hidden', :status => 403
    else
      if $IMAGE_BASE_PATH
        redirect_to $IMAGE_BASE_PATH + @image.path.split('/public/')[1]
      else
        redirect_to '/' + @image.path.split('/public/')[1]
      end
    end
  end

  def trackback
    if request.method == :post
      begin
        unless (@params.has_key?('url') and @params.has_key?('id'))
          @catched = false
          @message = 'need url and id '
        end
        article = Article.find(@params['id'], :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])

        unless article
          @catched = false
          @message = 'need valid id '
        end

        if @catched != false
          tb = Trackback.new
          tb.article_id = article.id
          tb.category = @params['category'] if @params['category'] 
          tb.blog_name = @params['blog_name'] if @params['blog_name']
          tb.title = @params['title'] || @params['url']
          tb.excerpt = @params['excerpt'] if @params['excerpt']
          tb.url = @params['url']

          tb.ip = request.remote_ip
          tb.created_at = Time.now
          tb.save
          if tb.errors.empty?
            @catched = true
            @message = 'success'
          else
            @catched = false
            @message = 'count:' + tb.errors.count.to_s
          end
        end
      rescue
        @catched = false
        @message = $!
      end
    else
      @catched = false
      @message = 'Please use HTTP POST'
    end
  end

  def catch_trackback
    if request.method == :post
      category = @params['category'] if @params['category'] 
      blog_name = @params['blog_name'] if @params['blog_name']
      title = @params['title'] || @params['url']
      excerpt = @params['excerpt'] if @params['excerpt']
      url = @params['url']
      
      ip = request.remote_ip
      created_at = Time.now
      @catched = true
    else
      @catched = false
    end
  end

  def catch_ping
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
    unless @session["person"]
      redirect_to :controller => "login", :action => "login_index"
      return false
    end
  end

  def add_cache_control
    if @lm
      @headers['Last-Modified'] = @lm.httpdate.to_s
    end
    if @maxage and @maxage == 0
      @headers['Cache-Control'] = 'no-cache'
    elsif @maxage
      @headers['Cache-Control'] = 'max-age=#{@maxage.to_s}'
    elsif @lm and @noindex and Time.now - @lm < 86400 * 7
      @headers['Cache-Control'] = 'max-age=86400'
    elsif @lm and Time.now - @lm < 86400 * 7
      @headers['Cache-Control'] = 'no-cache'
    else
      @headers['Cache-Control'] = 'public'
    end
  end

end
