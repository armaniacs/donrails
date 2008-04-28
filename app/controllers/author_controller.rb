require 'kconv'
class AuthorController < ApplicationController
  class << self
    include ApplicationHelper
  end
  @@dgc = don_get_config

  before_filter :author_authorize, :except => [:author_login_index, :authenticate]
  after_filter :compress
  after_filter :clean_memory

  auto_complete_for :author, :name
  auto_complete_for :category, :name

  layout "author", :except => [:login_index, :index]
  cache_sweeper :article_sweeper

  def author_authorize
    flash.keep
    flash[:note] = ''
    flash[:note2] = ''
    if request.env['PATH_INFO'] 
      flash[:op] = request.env['PATH_INFO'] 
    elsif request.env['REQUEST_URI']
      flash[:op] = request.env['REQUEST_URI']
    end
    unless session["author"] == "ok"
      flash[:pbp] = params
      session = request.session
      redirect_to :action => "author_login_index"
    end
    response.headers["X-donrails"] = "author_login"
  end

  def author_login_index
    flash.keep(:op)
    flash.keep(:pbp)
    render :action => "index"
  end


  def authenticate
    flash.keep(:op)
    flash.keep(:pbp)

    name = String.new
    password = String.new
    case request.method
    when :post
      c = params["nz"]
      if c
        namae = c["n"]
        password = c["p"]
      end

      if @user=Author.authenticate(namae, password)
        session["author"] = "ok"
        flash[:author_name] = @user.name
        redirect_to :action => :new_article
        return
      else
        flash[:notice] = "Wrong user/password pair."
        redirect_to :action => "author_login_index"
        return
      end
    else
      flash[:notice] = "Wrong method."
      redirect_to :action => "author_login_index"
      return
    end
  end

  def logout
    request.reset_session
    session = request.session
    session["author"] = "logout"
    redirect_to :action => "author_login_index"
  end

  def add_article
    flash.keep
    if c = params["article"]
      title = c["title"]
      body = c["body"]
      tburllist = [c["tburl"]]
      format = params["format"]

      if params["category"] and params["category"]['name']
        category0 = params["category"]['name']
        ca = category0.split(/\s+/)
      end

      if params["author"] and params["author"]['name']
        author_name = params["author"]['name']
        author = Author.find(:first, :conditions => ["name = ?", author_name])
        if author == nil
          render :status => 500, :text =>  'Non-registered Author Name. Please submit this article after author registration. Or contact to administrator.'
          return
        end
      else
        render :text => 'invalid entry', :status => 500
        return
      end

      get_ymd
      aris1 = Article.new("title" => title, "body" => body, "size" => body.size,
 "format" => format)
      aris1.article_date = @ymd if @ymd

      aris1.create_enrollment
      aris1.enrollment.title = title
      aris1.enrollment.save

      preview = 0
      if params['preview'] && params['preview']['preview'].to_i == 1
        preview = 1
        aris1.hidden = 2
      end

      if params['hideid'] && params['hideid']['hidden'].to_i == 1
        aris1.hidden = 1
      end
      aris1.author_id = author.id if author

      if ca
        ca.each do |ca0|
          begin
            b = Category.find(:first, :conditions => ["name = ?", ca0])
            if b == nil
              b = Category.new("name" => ca0)
              b.save
            end
          rescue
            b = Category.new("name" => ca0)
            b.save
          end
          DonaCa.create(:article => aris1, :category => b)
        end
      end

      if aris1.errors.empty?
        aris1.save
        
        if tburllist
          baseurl = don_get_config.baseurl.split('/')
          baseurl << 'archives'
          baseurl << 'id'
          if aris1.enrollment_id
            baseurl << aris1.enrollment_id.to_s
          else
            baseurl << aris1.id.to_s
          end
          articleurl = baseurl.join('/')
          aris1.send_trackback(articleurl, tburllist)
        end

        ca.clear if ca
        c.clear
        if preview == 1
          redirect_to :action => 'preview_article', :id => aris1.id
        else
          redirect_to :action => "manage_article"
        end
      else
        emg = ''
        aris1.errors.each_full do |msg|
          emg += msg
        end
        render :text => emg, :status => 403
      end
    else
      render :text => 'invalid entry', :status => 404
    end
  end

  def form_article
    flash.keep
    @dgc = @@dgc
    if params['pickid'] 
      begin
        @article = Article.find(params['pickid'].to_i)
      rescue
        render :text => 'no entry', :status => 404
      end
    elsif params['id'] 
      begin
        @article = Article.find(params['id'].to_i)
      rescue
        render :text => 'no entry', :status => 404
      end
    else
      render :text => 'no entry', :status => 404
    end
  end
  alias :preview_article :form_article

  def preview_article_confirm
    flash.keep
    if params[:commit] == 'create'
      article = Article.find(params[:article][:id])
      article.hidden = 0
      article.save
    elsif params[:commit] == 'delete'
      Article.delete(params[:article][:id])
    end
    redirect_to :action => :manage_article
  end

  def manage_article
    flash.keep
    author = Author.find_by_name(flash[:author_name])
    unless author
      render :text => "no for your entry", :status => 404
      return
    end

    if params[:nohidden] == '1'
      @articles = Article.paginate(:page => params[:page], :per_page => 30,
                                   :order => 'id DESC',
                                   :conditions => ["hidden IS NULL OR hidden = 0 AND author_id = ?", author.id]
                                   )
    else
      @articles = Article.paginate(:page => params[:page], :per_page => 30,
                                   :order => 'id DESC',
                                   :conditions => ["author_id = ?", author.id]
                                   )
    end
  end


  def fix_article
    flash.keep
    if c = params["article"] and params["newid"]
      format = params["format"]
      catname = params["catname"]

      title = c["title"]
      body = c["body"]
      tburllist = [c["tburl"]]
      id = c["id"].to_i
      article_date = c["article_date"]
      reentry = params["newid"]["#{id}"]

      hideid = params["hideid"]["#{id}"] if params["hideid"]
      
      referer = c["referer"] if c["referer"] 

      if params[:category]
        newcategory = params['category']['name'].nil? ? nil : params["category"]['name']
      end

      # original check
      oa = Article.find(id) # oa is original Article.
      
      if oa.author.name == flash[:author_name] && format == oa.format and title == oa.title and body == oa.body and c["author_name"] and c["author_name"].length and !oa.author.nil? && c["author_name"] == oa.author.name and newcategory.size == 0 and article_date == oa.article_date.to_date.to_s and hideid == oa.hidden.to_s
        flash[:note2] = '<br>You have not change:' + id.to_s
        
        cat_ka_in = Array.new
        if catname
          catname.each do |k,v|
            if v.to_i == 1
              cat_ka_in.push(k.to_i)
            end
          end
        end
        cat_ka_in.sort!.uniq!

        cat_ka_oa = Array.new       
        oa.categories.each do |cat|
          cat_ka_oa.push(cat.id)
        end
        cat_ka_oa.sort!.uniq!

        if cat_ka_in == cat_ka_oa
          if referer
            redirect_to :action => referer
          else
            redirect_to :action => "manage_article"
          end   
          return false
        end
      end
      if reentry == "0"
        aris = Article.find(id)
        aris.categories.clear
      elsif reentry == "1"
        aris = Article.new
      end

      preview = 0

      if aris
        if params['preview'] && params['preview']['preview'].to_i == 1
          preview = 1
          aris.hidden = 2
        elsif hideid == "0"
          aris.hidden = 0
        elsif hideid == "1"
          aris.hidden = 1
        end
        aris.title = title
        aris.body = body
        aris.format = format
        aris.article_date = article_date

        if oa.enrollment_id
          aris.enrollment_id = oa.enrollment_id
          oa.hidden = 1
          oa.save
        else
          aris.build_enrollment
          aris.enrollment.title = title
          aris.enrollment.save
        end

        if tburllist
          baseurl = don_get_config.baseurl.split('/')
          baseurl << 'archives'
          baseurl << 'id'
          if aris.enrollment_id
            baseurl << aris.enrollment_id.to_s
          else
            baseurl << aris.id.to_s
          end
          articleurl = baseurl.join('/')
          aris.send_trackback(articleurl, tburllist)
        end
        
        if c["author_name"] and c["author_name"].length > 0
          au = Author.find(:first, :conditions => ["name = ?", c["author_name"]])
          aris.author_id = au.id
        elsif c['author_id']
          aris.author_id = c['author_id']
        end

        if newcategory
          nca = newcategory.split(/\s+/)
          nca.each do |ca|
            nb = Category.find(:first, :conditions => ["name = ?", ca])
            if nb
              DonaCa.create(:article => aris, :category => nb)
            else
              nb = Category.new("name" => ca)
              nb.save
              DonaCa.create(:article => aris, :category => nb)
            end
          end
        end
        
        if catname
          catname.each do |k, v|
            begin
              if v.to_i == 1
                b = Category.find(k.to_i)
                DonaCa.create(:article => aris, :category => b)
              else
              end
            rescue
            end
          end
        end

        oa.don_attachments.each do |atta|
          DonaDaa.create(:article => aris, :don_attachment => atta)
        end

        aris.save
      end
    end

    if preview == 1
      redirect_to :action => 'preview_article', :id => aris.id
    elsif referer
      redirect_to :action => referer
    else
      redirect_to :action => "manage_article"
    end
  end

  def delete_article
    flash.keep
    flash[:note] = ''
    flash[:note2] = ''
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if Article.exists?(k.to_i) &&
            b = Article.find(k.to_i)
          if b.author.name == flash[:author_name]
            b_cat = b.categories
            b.categories.delete(b_cat)
          
            b_comment = b.comments
            b_comment.each do |bc|
              Comment.destroy(bc.id)
            end
            b.comments.delete(b_comment)
            
            b.pictures.each do |bp|
              bp.articles.clear
              bp.save
            end
            flash[:note2] += '<br>Delete:' + k
            b.destroy
          else
            flash[:note2] += '<br>Not exists (no delete):' + k.to_s
          end
        else
          flash[:note2] += '<br>Not exists (no delete):' + k.to_s
        end
      end
    end
    if c = params["hideid"]
      c.each do |k, v|
        if Article.exists?(k.to_i)
          pf = Article.find(k.to_i)
          if pf.author.name == flash[:author_name]

            stmp = pf.hidden
            if v.to_i == 1 and pf.hidden != 1
              pf.update_attribute('hidden', 1)
            elsif v.to_i == 0 and pf.hidden != 0
              pf.update_attribute('hidden', 0)
            end
          else
            flash[:note2] += '<br>Hyde status:' + k.to_s + ' is not ' + flash[:author_name] + '\'s article.'
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k.to_s + ' is ' + pf.hidden.to_s
          end
        end
      end
    end # end of hideid
    @tmp_k = Array.new
    if c = params["catid"]
      c.each do |k, v|
        if v.to_i == 1
          @tmp_k.push(k)
        end
      end
    end
    if @tmp_k && @tmp_k.size > 0
      @articles = Article.find(@tmp_k)
    else
      redirect_to :action => "manage_article"
    end
  end

end
