class Admin::HnfController < AdminController
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
#    redirect_to :action => 'index'
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
