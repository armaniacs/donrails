class Admin::BanlistController < AdminController

  def manage_banlist
    @banlists_pages, @banlists = paginate(:banlist, :per_page => 30,
                                          :order => 'id DESC'
                                          )
  end

  def delete_banlist
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Banlist.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_banlist"
  end

  def add_banlist
    if c = params["banlist"]
      flash[:pattern] = c['pattern']
      flash[:teststring] = c['teststring'] 
      flash[:format] = params['format']

      if c['add'] == '1' and c["pattern"].size > 0 and params["format"]
        aris1 = Banlist.new("pattern" => c["pattern"],
                            "format" => params["format"],
                            "white" => c["white"])
        banlist_test_by_valid(c["pattern"], params["format"])
        unless flash[:ban]
          aris1.save 
          flash[:note2] =  '"' + c["pattern"] + '" is saved as ' + params["format"]
        else
          aris1.destroy
        end
      elsif c["pattern"] and c["pattern"].size > 0 and params["format"]
        if banlist_test_by_ar(c["pattern"], c["teststring"], params["format"])
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
    if params["banlist"] and checktext = params["banlist"]["pattern"]
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

end
