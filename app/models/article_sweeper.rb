class ArticleSweeper < ActionController::Caching::Sweeper
# XXX #  observe Article, Category, Comment, Trackback, Enrollment, Picture
  observe Article, Category, Comment, Trackback, Enrollment, Picture

  def after_save(record)
    expire_for(record)
  end

  def after_destroy(record)
    expire_for(record)
  end

  def expire_for(record)
    case record
    when Article
      ep_notes
      ep_category
      ep_articles_long
      ep_trigger_title_a
      ep_author(record)
      ep_atom(record)

      expire_action(:controller => '/notes', :action => %w(pick_article_a pick_article_a2))

      expire_page(:controller => '/notes', :action => %w(index articles_long category_tree_list_a sitemap))
      expire_page(:controller => '/rdf', :action => %w(rdf_recent rss2_recent))
      expire_page(:controller => '/notes', :action => %w(show_title), :id => record.id)
      expire_page(:controller => '/rdf', :action => %w(rdf_article rss2_article), :id => record.id)
      expire_page(:controller => '/notes', :action => %w(show_enrollment), :id => record.enrollment_id) if record.enrollment_id
      expire_page(:controller => '/rdf', :action => %w(rdf_enrollment rss2_enrollment), :id => record.enrollment_id) if record.enrollment_id
      expire_page(:controller => '/notes', :action => %w(show_enrollment show_title), :id => record.enrollment_id - 1) if record.enrollment_id
      expire_page(:controller => '/notes', :action => %w(show_title2), :title => record.title)
      expire_page(:controller => '/rdf', :action => %w(rdf_article rss2_article), :title => record.title)
      expire_page(:controller => '/notes', :action => 'show_month', :year => record.article_date.year, :month => record.article_date.month)
      expire_page(:controller => '/notes', :action => 'show_nnen', :day => record.article_date.day, :month => record.article_date.month)
      expire_page(:controller => '/notes', :action => 'show_date', :day => record.article_date.day, :month => record.article_date.month, :year => record.article_date.year)

    when Category
      expire_page(:controller => '/notes', :action => 'category_select_a')
      expire_page(:controller => '/notes', :action => 'category_tree_list_a')
      expire_page(:controller => '/notes', :action => 'noteslist')
    when Comment
      expire_page(:controller => '/notes', :action => 'noteslist')
      expire_for(record.article)
    when Trackback
      expire_page(:controller => '/notes', :action => 'noteslist')
      expire_for(record.article)
    when Picture, DonAttachment
      expire_page(:controller => '/notes', :action => 'noteslist')
      record.articles.each do |ra|
        expire_for(ra)
      end
    when Enrollment
      expire_page(:controller => '/notes', :action => 'show_enrollment', :id => record.id)
      expire_page(:controller => '/notes', :action => 'noteslist')
    end

  end

  def ep_notes
    expire_page(:controller => '/notes', :action => 'index')
    begin
      ppfile = RAILS_ROOT + '/public/index.html'
      File.delete ppfile
      logger.info "Expired page: #{ppfile}"
    rescue
    end

    expire_page(:controller => '/notes', :action => 'noteslist')
    begin
      ppdir = RAILS_ROOT + "/public/archives/listpages/page"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /(\d+).html/
          expire_page(:controller => '/notes', :action => 'noteslist', :page => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end
  end

  def ep_author(record)
    expire_page(:controller => '/notes', :action => 'articles_author', :id => record.author_id)
    begin
      ppdir = RAILS_ROOT + "/public/archives/articles_author/#{record.author_id}/page"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /(\d+).html/
          expire_page(:controller => '/notes', :action => 'articles_author', :id => record.author_id, :page => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end
  end

  def ep_articles_long
    expire_page(:controller => '/notes', :action => 'articles_long')
    begin
      ppdir = RAILS_ROOT + "/public/archives/articles_long/page"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /(\d+).html/
          expire_page(:controller => '/notes', :action => 'articles_long', :page => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end
  end

  def ep_category
    expire_page(:controller => '/notes', :action => 'recent_category_title_a')
    begin
      ppdir = RAILS_ROOT + "/public/archives/recent_category_title_a"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /(\w+).html/
          expire_page(:controller => '/notes', :action => 'recent_category_title_a', :category => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end

    clall = Category.find(:all)
    clall.each do |rc|
      expire_page "/rdf/rdf_category/#{rc.name}/feed.xml"
      expire_page "/rdf/rss2_category/#{rc.name}/feed.xml"

      pagemaxnum = rc.articles.size / 30 + 1
      for i in 1..pagemaxnum
        expire_page(:controller => '/notes', :action => %w(show_category show_category_noteslist) , :category => rc.name, :page => i)
        expire_page(:controller => '/notes', :action => %w(show_category show_category_noteslist) , :id => rc.id, :page => i)
        expire_page(:controller => '/rdf', :action => %w(rdf_category rss2_category) , :category => rc.name, :page => i)
      end
    end

  end

  def ep_atom(record)
    expire_page "/atom/feed.xml"
    expire_page(:controller => '/atom', :action => 'feed', :page => 1)
    expire_page(:controller => '/atom', :action => 'feed', :aid => record.id)
    begin
      ppdir = RAILS_ROOT + "/public/atom/feed/page"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /^(\d+)/
          expire_page(:controller => '/atom', :action => 'feed', :page => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end
  end

  def ep_trigger_title_a
    expire_page(:controller => '/notes', :action => 'recent_trigger_title_a')
    expire_page(:controller => '/notes', :action => 'recent_trigger_title_a', :trigger => 'recents')
    expire_page(:controller => '/notes', :action => 'recent_trigger_title_a', :trigger => 'trackbacks')
    expire_page(:controller => '/notes', :action => 'recent_trigger_title_a', :trigger => 'comments')
    expire_page(:controller => '/notes', :action => 'recent_trigger_title_a', :trigger => 'long')

    begin
      ppdir = RAILS_ROOT + "/public/archives/recent_trigger_title_a"
      ppdir2 = Dir.entries(ppdir)
      ppdir2.each do |x|
        if x =~ /(\w+).html/
          expire_page(:controller => '/notes', :action => 'recent_trigger_title_a', :trigger => $1)
        end
      end
    rescue Errno::ENOENT
    rescue
      logger.info $!
    end
  end

end
