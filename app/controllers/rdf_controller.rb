class RdfController < ApplicationController
  before_filter :set_charset
  caches_page :rdf_recent, :rdf_article, :rdf_category, :rdf_enrollment, :rss2_recent, :rss2_article, :rss2_category, :rss2_enrollment
  after_filter :compress
  layout nil
##  session :off ## comment out at 2.3.2

  def rdf_recent
    headers["Content-Type"] = "application/xml; charset=utf-8"
    @recent_articles = Article.find(:all, :order => "article_mtime DESC", :limit => 20, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    unless @recent_articles.empty? then
      @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
    end
  end
  alias :rss2_recent :rdf_recent

  def rdf_article
    begin
      if params['id'] and @article = Article.find(params['id'], :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
        @rdf_article = @article.id
        @lm = @article.article_mtime.gmtime if @article and @article.article_mtime
        headers["Content-Type"] = "application/xml; charset=utf-8"
      else
        render :text => "no entry", :status => 404
      end
    rescue
      logger.info $!
      render :text => "no entry", :status => 404
    end
  end
  alias :rss2_article :rdf_article

  def rdf_enrollment
    begin
      if params['id'] and @enrollment = Enrollment.find(params['id'], :conditions => ["enrollments.hidden IS NULL OR enrollments.hidden = 0"])
        @rdf_enrollment = @enrollment.id
        @lm = @enrollment.updated_at.gmtime if @enrollment and @enrollment.updated_at
        headers["Content-Type"] = "application/xml; charset=utf-8"
      else
        render :text => "no entry", :status => 404
      end
    rescue
      render :text => "no entry", :status => 404
    end
  end
  alias :rss2_enrollment :rdf_enrollment

  def rdf_search
    headers["Content-Type"] = "application/xml; charset=utf-8"
    @lm = Time.now.gmtime
    @recent_articles = Article.search(params["q"])
    @rdf_search = params["q"]
    if @recent_articles == nil
      render :text => "no entry"
    end
  end
  alias :rss2_search :rdf_search

  def rdf_category
    headers["Content-Type"] = "application/xml; charset=utf-8"
    if params['id']
      @category = Category.find(params['id'])
    else
      @category = Category.find(:first, :conditions => ["name = ?", params['category']])
    end
    if @category == nil
      params["q"] = params["category"]
      redirect_to :action => 'rdf_search', :q => params["category"]
    else
      ccs = collect_category_ids(@category)
      @recent_articles = Array.new
      ccs.each do |cid|
        @recent_articles = @recent_articles | 
          Article.paginate(:page => params[:page], :per_page => 20,
                           :order => 'articles.id DESC',
                           :joins => "JOIN dona_cas on (dona_cas.article_id=articles.id and dona_cas.category_id=#{cid})",
                           :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"]
                           )
      end
      @recent_articles = @recent_articles.sort.reverse
      @rdf_category = @category.name
      unless @recent_articles.empty? then
        @lm = @recent_articles.first.article_mtime.gmtime if @recent_articles.first.article_mtime
      end
    end
  end
  alias :rss2_category :rdf_category

end
