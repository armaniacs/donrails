require 'rexml/document'
require 'cgi'

# rfc4287

class AtomController < ApplicationController
  layout "atom", :only => [
    :preview
  ]
  before_filter :wsse_auth, :except => [:feed]
  cache_sweeper :article_sweeper, :only => [ :post, :edit ]
  caches_page :feed
  after_filter :compress
  after_filter :clean_memory

  def wsse_auth
    if request.env["HTTP_X_WSSE"]
      if false == wsse_match(request.env["HTTP_X_WSSE"])
        render :text => "you are not valid user for atom.", :status => 401
      end
    elsif request.env["REMOTE_ADDR"] == "127.0.0.1"
      # for debug
    else
      render :text => "you are not valid user for atom. Use with WSSE.", :status => 401
    end
  end

  # atom endpoint 
  def index
    @latest_article = Article.find(:first, :order => 'id DESC', :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    @recent_articles = Article.find(:all, :order => 'id DESC', :limit => 20, :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
  end

  # atom feed
  def feed
    if @params['id'] == nil
      @articles_pages, @articles = paginate(:article, :per_page => 20, :order_by => 'id DESC', :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
    else
      begin
        @article = Article.find(@params['id'], :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      rescue
        render :text => "no this id", :status => 403
      end
    end
  end

  # atom post
  def post
    if request.method == :post
      begin
        author = Author.find(:first, :conditions => ["name = ?", @user])
        if @params['id']
          aris1 = Article.new("id" => @params['id'])
        else
          aris1 = Article.new
        end
        atom_update_article2(aris1, request.raw_post)
        aris1.author_id = author.id if author        
        aris1.save
        @article = aris1
        render :status => 201 # 201 Created @ Location
      rescue
        p $!
        render :status => 400
      end
    else
      render :status => 502
    end
  end

  # atom edit
  def edit
    if request.method == :put
      begin
        author = Author.find(:first, :conditions => ["name = ?", @user])
        aris1 = Article.find(@params['id'])
        atom_update_article2(aris1, request.raw_post)
        aris1.author_id = author.id if author        
        aris1.save
        @article = aris1
        render :action => "post", :status => 200
      rescue
        p $!
        render :status => 400
      end
    elsif request.method == :delete
      begin
        Article.destroy(@params['id'])
        render :text => "dslete #{@params['id']}", :status => 204
      rescue
        render :text => "no method #{request.method}", :status => 403
      end
    else
      render :status => 502
    end
  end

  # beta testing..
  def categories
    if @params['id'] == nil
      render :text => "no method #{request.method}", :status => 400
    end

    if @params['id']
      begin
        @article = Article.find(@params['id'], :conditions => ["articles.hidden IS NULL OR articles.hidden = 0"])
      rescue
        render :text => "no this id", :status => 400
      end
    end
  end

  def image_post
    if request.method == :post
      begin
        @image = Image.new
        atom_parse_image(@image, request.raw_post)
        @image.save
        render :status => 201
      rescue
        p $!
        render :status => 400
      end
    else
      render :status => 405
    end
  end

end
