require 'kconv'
class LoginController < ApplicationController

  include Akismet

  class << self
    include ApplicationHelper
  end
  @@dgc = don_get_config

  before_filter :authorize, :except => [:login_index, :authenticate]
  after_filter :compress
  after_filter :clean_memory

  auto_complete_for :author, :name
  auto_complete_for :category, :name

  cache_sweeper :article_sweeper, :only => [ :delete_article, :new_article, :fix_article, :add_category, :delete_category, :add_article, :delete_picture, :delete_trackback, :delete_comment, :delete_enrollment ]

  layout "login", :except => [:login_index, :index]

  verify_form_posts_have_security_token :only => [
    :fix_article, :authenticate, :delete_article,
    :delete_unwrite_author, :add_banlist, :delete_banlist,
    :add_blogping, :delete_blogping, :delete_comment,
    :delete_trackback, :picture_save, :add_article, :add_author
  ]

  def login_index
    flash.keep(:op)
    render :action => "index"
  end

  protected
  def authorize
    if @request.env['PATH_INFO'] 
      flash[:op] = @request.env['PATH_INFO'] 
    elsif @request.env['REQUEST_URI']
      flash[:op] = @request.env['REQUEST_URI']
    end

    unless @session["person"] == "ok"
      @session = @request.session
      redirect_to :action => "login_index"
    end
    @response.headers["X-donrails"] = "login"
  end
  
  public
  def authenticate
    flash.keep(:op)
    name = String.new
    password = String.new
    case @request.method
    when :post
      c = @params["nz"]
      if c
        namae = c["n"]
        password = c["p"]
      end

      if namae == @@dgc.admin_user and password == @@dgc.admin_password
        @request.reset_session
        @session = @request.session
        @session["person"] = "ok"

        if flash[:op] =~ /^\/login\/?$/
          redirect_to :action => "new_article"
          return
        elsif flash[:op]
          redirect_to flash[:op] 
          return
        else
          redirect_to :action => "new_article"
          return
        end
      else
        flash[:notice] = "Wrong Password. Please input carefully."
        if flash[:op] == nil
          render :status => 403, :text => 'fail'
          return
        elsif flash[:op] == '/login/authenticate'
          redirect_to '/login' 
          return
        else
          redirect_to flash[:op] 
          return
        end

      end
    else
      flash[:notice] = "Wrong method."
      redirect_to :action => "login_index"
      return
    end
  end

  def new_article
    begin
      @categories = Category.find_all
      retval = Article.find_by_sql("SELECT format FROM articles ORDER BY id DESC LIMIT 1")
    rescue
      retval = []
    end
    @dgc = @@dgc
    if retval.nil? || retval.empty? then
      @defaultformat = 'plain'
    else
      @defaultformat = retval[0].format
    end
  end

  def logout
    @request.reset_session
    @session = @request.session
    @session["person"] = "logout"
    redirect_to :action => "login_index"
  end

  ## category
  def manage_category
    if @params['id']
      @category = Category.find(@params['id'])
      if @category.parent_id
        @parent = Category.find(@category.parent_id)
      end
    end

    @categories_pages, @categories = paginate(:category,:per_page => 30,:order_by => 'id DESC')

    @roots = Category.find(:all, :conditions => ["parent_id IS NULL"])
    @size = Category.find(:all).size
  end

  def add_category
    c = @params["category"]
    if c
      parent = Category.find(:first, :conditions => ["name = ?", c["parent_name"]])
      aris1 = Category.find(:first, :conditions => ["name = ?", c["name"]])
      
      if parent and aris1
        aris1.parent_id = parent.id
        flash[:note] = "Change #{c['name']}'s parent. New parent is #{c["parent_name"]}."
      elsif parent
        aris1 = Category.new("name" => c["name"])
        aris1.save
        parent.add_child(aris1)
        flash[:note] = "Add new category:#{c['name']}. Her parent is #{c["parent_name"]}."
      elsif aris1
      else
        aris1 = Category.new("name" => c["name"])
        flash[:note] = "Add new category:#{c['name']}."
      end
      aris1.description = c["description"]
      aris1.save
    end
    redirect_to :action => "manage_category"
  end

  def delete_category
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        
        cas = Category.find(:all, :conditions => ["parent_id = ?", k.to_i])
        cas.each do |ca|
          ca.parent_id = nil
          ca.save
        end

        b = Category.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_category"
 end

  ## picture
  def manage_picture
    @pictures_pages, @pictures = paginate(:picture,:per_page => 30,:order_by => 'id DESC')
  end
  def manage_picture_detail
    if @params["id"]
      @picture = Picture.find(@params["id"])
    else
      redirect_to :back
    end
  end
  def edit_picture
    p2 = @params["picture"]
    if p2 and p2['id']
      @picture = Picture.find(p2['id'])
      @picture.article_id = p2['article_id'] if p2['article_id']
      @picture.comment = p2['comment'] if p2['comment']
      @picture.save
    end
    redirect_to :back
  end

  def delete_picture
    @flash[:note] = ''
    @flash[:note2] = ''
    begin
      if cf = @params["filedeleteid"]
        cf.each do |k, v|
          if v.to_i == 1
            pf = Picture.find(k.to_i)
            begin
              File.delete pf.path
            rescue
              @flash[:note] += '<br>' + $!
            end
            @flash[:note2] += '<br>Delete File:' + k
            Picture.delete(k.to_i)
          end
        end
      end
      if c = @params["deleteid"]
        c.each do |k, v|
          if v.to_i == 1
            Picture.delete(k.to_i)
            @flash[:note2] += '<br>Delete:' + k
          end
        end
      end
      if c = @params["hideid"]
        c.each do |k, v|
          pf = Picture.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        end
      end
    rescue
      @flash[:note] += '<br>' + $!
    end
    redirect_to :action => "manage_picture"
  end


  def picture_save
    begin
      @picture = Picture.new(@params['picture'])
      if @picture.save
        redirect_to :action => "manage_picture"
      else
        render :action => 'picture_get', :controller => 'notes'
      end
    rescue
      render :text => 'fail', :status => 403
    end
  end


  ## trackback
  def manage_trackback
    @trackbacks_pages, @trackbacks = paginate(:trackback, :per_page => 30,
                                              :order_by => 'id DESC')
  end

  def akismet_report
    if @params[:id] && @params[:sh] == 's'
      pf = Trackback.find(@params[:id])
      aq = {
        :comment_content => pf.excerpt,
        :comment_author_url => pf.url,
        :comment_author => pf.title
      }
      if don_get_config.akismet_key && submit_spam_to_akismet(aq)
        logger.info "[Akismet] Report SPAM"
        pf.update_attribute('hidden', 1)
        @flash[:note2] = "Report to Akismet: #{pf.id} is SPAM"
      end
    elsif @params[:id] && @params[:sh] == 'h'
      pf = Trackback.find(@params[:id])
      aq = {
        :comment_content => pf.excerpt,
        :comment_author_url => pf.url,
        :comment_author => pf.title
      }
      if don_get_config.akismet_key && submit_ham_to_akismet(aq)
        logger.info "[Akismet] Report HAM"
        pf.update_attribute('hidden', 0)
        @flash[:note2] = "Report to Akismet: #{pf.id} is HAM"
      end
    end
    redirect_to :back
  end

  def delete_trackback
    @flash[:note] = ''
    @flash[:note2] = ''
    begin
      if c = @params["deleteid"]
        c.each do |k, v|
          if v.to_i == 1
            Trackback.delete(k.to_i)
            @flash[:note2] += '<br>Delete:' + k
          end
        end
      end
      if c = @params["hideid"]
        c.each do |k, v|
          pf = Trackback.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        end
      end
    rescue
      @heading = 'fail delete_trackback'
    end
    redirect_to :action => "manage_trackback"
  end

  def delete_hidden_trackback_all
    @flash[:note] = ''
    @flash[:note2] = ''
    begin
      Trackback.delete_all "hidden = 1"
      @flash[:note2] += '<br>Delete: ALL hidden trackbacks'
    rescue
      @heading = 'fail delete_hidden_trackback_all'
    end
    redirect_to :action => "manage_trackback"
  end

  ## comment
  def manage_comment
    @comments_pages, @comments = paginate(:comment, :per_page => 30,
                                          :order_by => 'id DESC')
  end


  def delete_hidden_comment_all
    @flash[:note] = ''
    @flash[:note2] = ''
    begin
      Comment.delete_all "hidden = 1"
      @flash[:note2] += '<br>Delete: ALL hidden comments'
    rescue
      @heading = 'fail delete_hidden_comment_all'
    end
    redirect_to :action => "manage_comment"
  end

  def delete_comment
    @flash[:note] = ''
    @flash[:note2] = ''
    if c = @params["deleteid"]
      c.each do |k, v|
        if v.to_i == 1
          begin
            b = Comment.find(k.to_i)
            Comment.delete(k.to_i)
            @flash[:note2] += '<br>Delete:' + k
          rescue
          end
        end
      end
    end
    if c = @params["hideid"]
      c.each do |k, v|
        begin
          pf = Comment.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        rescue
        end
      end
    end
    redirect_to :action => "manage_comment"
  end

  def form_article
    if @params['pickid']
      begin
        @article = Article.find(@params['pickid'].to_i)
      rescue
        render :text => 'no entry', :status => 404
      end
    else
      render :text => 'no entry', :status => 404
    end
  end

  def fix_article
    if c = @params["article"] and @params["newid"]
      format = @params["format"]
      catname = @params["catname"]

      title = c["title"]
      body = c["body"]
      tburllist = [c["tburl"]]
      id = c["id"].to_i
      article_date = c["article_date"]
      reentry = @params["newid"]["#{id}"]

      hideid = @params["hideid"]["#{id}"] if @params["hideid"]
      
      referer = c["referer"] if c["referer"] 

      if @params[:category]
        newcategory = @params['category']['name'].nil? ? nil : @params["category"]['name']
      end

      # original check
      oa = Article.find(id) # oa is original Article.
      if format == oa.format and title == oa.title and body == oa.body and c["author_name"] and c["author_name"].length and !oa.author.nil? && c["author_name"] == oa.author.name and newcategory.size == 0 and article_date == oa.article_date.to_date.to_s and hideid == oa.hidden.to_s
        @flash[:note2] = '<br>You have not change:' + id.to_s
        
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
      if aris
        if hideid == "0"
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
        end

        if newcategory
          nca = newcategory.split(/\s+/)
          nca.each do |ca|
            nb = Category.find(:first, :conditions => ["name = ?", ca])
            if nb
              aris.categories.push_with_attributes(nb)
            else
              nb = Category.new("name" => ca)
              nb.save
              aris.categories.push_with_attributes(nb)
            end
          end
        end
        
        if catname
          catname.each do |k, v|
            begin
              if v.to_i == 1
                b = Category.find(k.to_i)
                aris.categories.push_with_attributes(b)
              else
              end
            rescue
            end
          end
        end

        aris.save
      end
    end
    if referer
      redirect_to :action => referer
    else
      redirect_to :action => "manage_article"
    end
  end

  def add_article
    if c = @params["article"]
      title = c["title"]
      body = c["body"]
      tburllist = [c["tburl"]]
      format = @params["format"]

      if @params["category"] and @params["category"]['name']
        category0 = @params["category"]['name']
        ca = category0.split(/\s+/)
      end

      if @params["author"] and @params["author"]['name']
        author_name = @params["author"]['name']
        author = Author.find(:first, :conditions => ["name = ?", author_name])
        if author == nil
          render :text => 'invalid entry', :status => 404
          return
        end
      else
        render :text => 'invalid entry', :status => 404
        return
      end

      get_ymd

      aris1 = Article.new("title" => title, "body" => body, "size" => body.size, "format" => format)
      aris1.article_date = @ymd if @ymd

      aris1.create_enrollment
      aris1.enrollment.title = title
      aris1.enrollment.save

      if @params["hideid"] and @params["hideid"]['hidden'].to_i == 1
        aris1.hidden = 1
      end
      aris1.author_id = author.id if author

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
        aris1.categories.push_with_attributes(b)
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

        ca.clear
        c.clear
        redirect_to :action => "manage_article"
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

  def manage_article
    if @params[:nohidden] == '1'
      @articles_pages, @articles = paginate(:article, :per_page => 30,
                                            :order_by => 'id DESC',
                                            :conditions => ["hidden IS NULL OR hidden = 0"]
                                            )
    else
      @articles_pages, @articles = paginate(:article, :per_page => 30,
                                            :order_by => 'id DESC'
                                            )
    end
  end

  def delete_article
    @flash[:note] = ''
    @flash[:note2] = ''
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if Article.exists?(k.to_i)
          b = Article.find(k.to_i)
          b_cat = b.categories
          b.categories.delete(b_cat)
          
          b_comment = b.comments
          b_comment.each do |bc|
            Comment.destroy(bc.id)
          end
          b.comments.delete(b_comment)
          
          b.pictures.each do |bp|
            bp.article_id = nil
            bp.save
          end
          @flash[:note2] += '<br>Delete:' + k
          b.destroy
        else
          @flash[:note2] += '<br>Not exists (no delete):' + k
        end
      end
    end
    if c = @params["hideid"]
      c.each do |k, v|
        if Article.exists?(k.to_i)
          pf = Article.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and pf.hidden != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and pf.hidden != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
#        else ## XXX
#          @flash[:note2] += '<br>Not exists (no hidden status change):' + k
        end
      end
    end
    redirect_to :action => "manage_article"
  end

  def manage_banlist
    @banlists_pages, @banlists = paginate(:banlist, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_banlist
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Banlist.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_banlist"
  end

  def add_banlist
    if c = @params["banlist"]
      flash[:pattern] = c['pattern']
      flash[:teststring] = c['teststring'] 
      flash[:format] = @params['format']

      if c['add'] == '1' and c["pattern"].size > 0 and @params["format"]
        aris1 = Banlist.new("pattern" => c["pattern"],
                            "format" => @params["format"],
                            "white" => c["white"])
        banlist_test_by_valid(c["pattern"], @params["format"])
        unless flash[:ban]
          aris1.save 
          flash[:note2] =  '"' + c["pattern"] + '" is saved as ' + @params["format"]
        else
          aris1.destroy
        end
      elsif c["pattern"] and c["pattern"].size > 0 and @params["format"]
        if banlist_test_by_ar(c["pattern"], c["teststring"], @params["format"])
          flash[:note2] =  'teststring: "' + c["teststring"] + '" is matched pattern: "' + c["pattern"] + '"'
        end
      else
        flash[:note2] =  'please input'
      end
      flash[:hit_tbs] = @hit_tbs if @hit_tbs
      flash[:hit_comments] = @hit_comments if @hit_comments
    end
    redirect_to :back
  end

  private
  def banlist_test_by_ar_ipaddr(pattern, teststring)
    @hit_tbs = Array.new
    Trackback.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.ip && tb.ip.match(/#{pattern}/)
        @hit_tbs.push(tb)
      end
    end
    @hit_comments = Array.new
    Comment.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.ipaddr && tb.ipaddr.match(/#{pattern}/)
        @hit_comments.push(tb)
      end
    end
    if teststring.size > 0
      return teststring.match(/#{pattern}/)
    else
      return nil
    end
  end

  def banlist_test_by_ar_hostname(pattern, teststring)
    @hit_tbs = Array.new
    Trackback.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.excerpt.match(/#{pattern}/) or tb.url.match(/#{pattern}/)
        @hit_tbs.push(tb)
      end
    end
    @hit_comments = Array.new
    Comment.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.title and tb.title.match(/#{pattern}/) 
        @hit_comments.push(tb)
      elsif tb.url and tb.url.match(/#{pattern}/) 
        @hit_comments.push(tb)
      elsif tb.body and tb.body.match(/#{pattern}/)
        @hit_comments.push(tb)
      end
    end
    if teststring.size > 0
      return teststring.match(/#{pattern}/)
    else
      return nil
    end
  end

  def banlist_test_by_ar_regexp(pattern, teststring)
    @hit_tbs = Array.new
    Trackback.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.blog_name.match(/#{pattern}/) or tb.title.match(/#{pattern}/) or tb.excerpt.match(/#{pattern}/)
        @hit_tbs.push(tb)
      end
    end
    @hit_comments = Array.new
    Comment.find(:all, :limit => 10, :order => 'id DESC').each do |tb|
      if tb.title.match(/#{pattern}/) or tb.body.match(/#{pattern}/)
        @hit_comments.push(tb)
      end
    end
    if teststring.size > 0
      return teststring.match(/#{pattern}/)
    else
      return nil
    end
  end

  def banlist_test_by_ar_string(pattern, teststring)
    @hit_tbs = Trackback.find(:all, :conditions => ["blog_name = ? OR title = ? OR excerpt = ?", pattern, pattern, pattern], :limit => 10, :order => 'id DESC')
    @hit_comments = Comment.find(:all, :conditions => ["title = ? OR body = ?", pattern, pattern], :limit => 10, :order => 'id DESC')

    if teststring.size > 0
      return teststring.match(/#{Regexp.quote(pattern)}/)
    else
      return nil
    end
  end

  def banlist_test_by_ar(pattern, teststring, format)
    unless teststring
      teststring = ''
    end
    if format == 'ipaddr'
      banlist_test_by_ar_ipaddr(pattern, teststring)
    elsif format == "string"
      banlist_test_by_ar_string(pattern, teststring)
    elsif format == "regexp"
      banlist_test_by_ar_regexp(pattern, teststring)
    elsif format == "hostname"
      banlist_test_by_ar_hostname(pattern, teststring)
    end
  end

  public
  def test_banlist
    if @params["banlist"] and checktext = @params["banlist"]["pattern"]
      banlist_test_by_valid(checktext)
    end
    redirect_to :back
  end

  private
  def banlist_test_by_valid(checktext, format=nil)
    flash[:ban] = nil
    flash[:ban_message] = String.new

    if format == nil
      if checktext =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
        format = 'ipaddr'
      end
    end

    tb = Trackback.new
    tb.excerpt = checktext
    tb.valid?
    if tb.errors.empty?
      flash[:note] = checktext
    else
      tb.errors.each_full do |msg|
        flash[:ban_message] += msg
      end
      flash[:ban] = tb.errors.count.to_s
      flash[:note] = checktext
    end

    unless flash[:ban]
      if format == 'ipaddr'
        tb = Trackback.new
        tb.ip = checktext
        tb.valid?
        if tb.errors.empty?
          flash[:note] = checktext
        else
          tb.errors.each_full do |msg|
            flash[:ban_message] += msg
          end
          flash[:ban] = tb.errors.count.to_s
          flash[:note] = checktext
        end
      end
    end

    unless flash[:ban]
      if checktext =~ /(http:\/\/[^\s"]+)/m
        tb = Trackback.new
        tb.url = checktext
        tb.valid?
        if tb.errors.empty?
          flash[:note] = checktext
        else
          tb.errors.each_full do |msg|
            flash[:ban_message] += msg
          end
          flash[:ban] = tb.errors.count.to_s
          flash[:note] = checktext
        end
      end
    end
    tb.destroy
  end

  public
  ## ping
  def manage_don_ping
    @don_pings_pages, @don_pings = paginate(:don_ping,:per_page => 30,:order_by => 'id DESC')
  end
  alias manage_ping manage_don_ping

  ## blogping
  def manage_blogping
    if defined?(don_get_config.baseurl)
      @flash[:note2] = 'BASEURL is ' + don_get_config.baseurl
    else
      @flash[:note2] = '現在Ping送信機能は無効です。baseurlを設定してください。'
    end
    @blogpings_pages, @blogpings = paginate(:blogping,:per_page => 30,:order_by => 'id DESC')
  end

  def delete_blogping
    c = @params["acid"].nil? ? [] : @params["acid"]
    flash[:note] = ''
    c.each do |k, v|
      b = Blogping.find(k.to_i)
      unless v.to_i == b.active
        b.active = v.to_i
        b.save
        if b.active == 1
          flash[:note] += '[Activate] ' + b.server_url + '<br>'
        else
          flash[:note] += '[Deactivate] ' + b.server_url + '<br>'
        end
      end
    end

    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Blogping.find(k.to_i)
        flash[:note] += '[Delete] ' + b.server_url + '<br>'
        b.destroy
      end
    end
    redirect_to :action => "manage_blogping"
  end

  def add_blogping
    if c = @params["blogping"]
      aris1 = Blogping.new("server_url" => c["server_url"])
      aris1.active = 1
      aris1.save
      flash[:note] = '[Add] ' + aris1.server_url + '<br>'
    end
    redirect_to :action => "manage_blogping"
  end


  # author
  def manage_author
    if @params['id']
      @author = Author.find(@params['id'])
    end
    @authors_pages, @authors = paginate(:author, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_unwrite_author
    c = @params["unwriteid"].nil? ? [] : @params["unwriteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        if b.writable == 1
          b.writable = 0
          b.save
        else
          b.writable = 1
          b.save          
        end
      end
    end
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_author"
  end

  def add_author
    if c = @params["author"]
      aris1 = Author.find(:first, :conditions => ["name = ?", c["name"]])
      unless aris1
        aris1 = Author.new("name" => c["name"])
      end
      aris1.pass = c["pass"]
      aris1.nickname = c["nickname"]
      aris1.summary = c["summary"]
      aris1.writable = 1
      aris1.save
    end
    redirect_to :action => "manage_author"
  end


  def manage_enrollment
    if @params[:nohidden] == '1'
      @enrollments_pages, @enrollments = paginate(:enrollment, :per_page => 30,
                                                  :order_by => 'id DESC',
                                                  :conditions => ["hidden IS NULL OR hidden = 0"]
                                                  )
    else
      @enrollments_pages, @enrollments = paginate(:enrollment, :per_page => 30,
                                                  :order_by => 'id DESC'
                                                  )
    end
  end


  def delete_enrollment
    @flash[:note] = ''
    @flash[:note2] = ''
    now_delete = Array.new
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if Enrollment.exists?(k.to_i)
          b = Enrollment.find(k.to_i)
          b.articles.each do |ba|
            ba.enrollment_id = nil
            ba.save
          end
          @flash[:note2] += '<br>Delete:' + k
          now_delete.push(k)
          b.destroy
        else
          @flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = @params["hideid"]
      c.each do |k, v|
        if Enrollment.exists?(k.to_i)
          pf = Enrollment.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and stmp != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and stmp != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          unless now_delete.include?(k)
            @flash[:note2] += '<br>Not exists:' + k
          end
        end
      end
    end
    redirect_to :action => "manage_enrollment"
  end

  def manage_don_env
    if @params['id']
      @donenv = DonEnv.find(@params['id'])
    end
    @don_envs = DonEnv.find_all
  end

  def add_don_env
    if c = @params["donenv"]
      if c['id'] && c['id'].size > 0
        aris1 = DonEnv.find(c['id'].to_i)
      else aris1
        aris1 = DonEnv.new
      end
      aris1.image_dump_path = c["image_dump_path"]
      aris1.admin_user = c["admin_user"]
      aris1.admin_password = c["admin_password"]
      aris1.admin_mailadd = c["admin_mailadd"]
      aris1.rdf_title = c["rdf_title"]
      aris1.rdf_description = c["rdf_description"]
      aris1.rdf_copyright = c["rdf_copyright"]
      aris1.rdf_managingeditor = c["rdf_managingeditor"]
      aris1.rdf_webmaster = c["rdf_webmaster"]
      aris1.baseurl = c["baseurl"]
      aris1.url_limit = c["url_limit"]
      aris1.default_theme = c["default_theme"]
      aris1.trackback_enable_time = c["trackback_enable_time"].to_i
      aris1.akismet_key = c["akismet_key"]
      aris1.notify_level = c["notify_level"].to_i

      aris1.save
    end
    begin
      don_delete_cache_all
      @flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      @flash[:note2] = $!
    end
    redirect_to :action => "manage_don_env"
  end

  def delete_don_env
    @flash[:note] = ''
    @flash[:note2] = ''
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if DonEnv.exists?(k.to_i)
          b = DonEnv.find(k.to_i)
          @flash[:note2] += '<br>Delete:' + k
          b.destroy
        else
          @flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = @params["hideid"]
      c.each do |k, v|
        if DonEnv.exists?(k.to_i)
          pf = DonEnv.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and pf.hidden != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and pf.hidden != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          @flash[:note2] += '<br>Not exists:' + k
        end
      end
    end

    begin
      don_delete_cache_all
      @flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      @flash[:note2] = $!
    end

    redirect_to :action => "manage_don_env"
  end

  # RBL
  def manage_don_rbl
    @don_rbls = DonRbl.find_all
  end

  def add_don_rbl
    if c = @params["donrbl"]
      if c['id'] && c['id'].size > 0
        aris1 = DonRbl.find(c['id'].to_i)
      else aris1
        aris1 = DonRbl.new
      end
      aris1.rbl_type = @params["format"]
      aris1.hostname = c["hostname"]
      aris1.save
    end
    redirect_to :action => "manage_don_rbl"
  end

  def delete_don_rbl
    @flash[:note] = ''
    @flash[:note2] = ''
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if DonRbl.exists?(k.to_i)
          b = DonRbl.find(k.to_i)
          @flash[:note2] += '<br>Delete:' + k
          b.destroy
        else
          @flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = @params["hideid"]
      c.each do |k, v|
        if DonRbl.exists?(k.to_i)
          pf = DonRbl.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and pf.hidden != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and pf.hidden != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            @flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          @flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    redirect_to :action => "manage_don_rbl"
  end

  def delete_cache
    begin
      don_delete_cache_all
      @flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      @flash[:note2] = $!
    end
    redirect_to :action => "manage_cache"
  end

  # HNF
  def hnf_save_all
    @articles = Article.find(:all, :order => "article_date")
    rf = hnf_save_date_inner_all
    fftmp = open("/tmp/hnfall.tgz", "r")
    send_data(fftmp.read, :filename => rf)
    fftmp.close
  end

  def hnf_save_date
    get_ymd
    if @ymd
      @articles = Article.find(:all, :conditions => ["article_date = ?", @ymd])
    else
      render_text = "please input date w/valid format."
    end
    inner, hnf_file = hnf_save_date_inner
    send_data(inner, :filename => hnf_file) ## send file OK
    redirect_to :action => 'index'
  end

  def hnf_save_date_inner_all
    firstday = @articles.first.article_date.to_date.to_s.gsub('-','')
    lastday = @articles.last.article_date.to_date.to_s.gsub('-','')
    hnf_tar_file_name = "hnf-#{firstday}_#{lastday}.tgz"

    if File.exist? "/tmp/hnfall.tgz"
      File.delete "/tmp/hnfall.tgz"
    end

    day0 = Time.new
    day1 = day0
    hnfbody = "OK \n\n"
    Dir.mkdir("/tmp/.donrails-tmp") unless FileTest.exist? "/tmp/.donrails-tmp"
    predir = "/tmp/.donrails-tmp/" + Process.pid.to_s 
    Dir.mkdir(predir) unless FileTest.exist? predir
    @articles.each do |article|
      day0 = article.article_date.to_date 
      if day1 != day0
        ymd2 = day1.to_date.to_s.gsub('-','')
        hnf_file = "#{predir}/d#{ymd2}.hnf"
        unless hnfbody == "OK \n\n"
          tmpf = File.new(hnf_file, "w")
          tmpf.puts Kconv.toeuc(hnfbody)
          tmpf.close
        end

        day1 = article.article_date.to_date 
        hnfbody = "OK \n\n"
      end 
      
      hnfbody += 'CAT '
      article.categories.each do |cat|
        hnfbody += cat.name 
      end 
      hnfbody += "\n"

      if article.title
        if article.title =~ /^https?:\/\// 
          hnfbody += "LNEW "
        else
          hnfbody += "NEW "
        end
        hnfbody += article.title + "\n" 
      end
      hnfbody += article.body + "\n"
    end
    system("cd #{predir} && tar zcf /tmp/hnfall.tgz *.hnf")
    return hnf_tar_file_name
  end

  def hnf_save_date_inner
    day0 = Time.new
    day1 = day0
    hnfbody = "OK \n\n"
    @articles.each do |article|
      day0 = article.article_date.to_date 
      if day1 != day0 
        day1 = article.article_date.to_date 
      end 
      
      hnfbody += 'CAT '
      article.categories.each do |cat|
        hnfbody += cat.name 
      end 
      hnfbody += "\n"

      if article.title =~ /^https?:\/\// 
        hnfbody += "LNEW "
      else
        hnfbody += "NEW "
      end
      hnfbody += article.title + "\n"
      hnfbody += article.body + "\n"
    end
    ymd2 = day0.to_date.to_s.gsub('-','')
    hnf_file = "d#{ymd2}.hnf"
    return hnfbody, hnf_file
  end

end
