class ArticleSweeper < ActionController::Caching::Sweeper
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
      expire_action(:controller => 'notes', :action => %w(pick_article_a pick_article_a2))

      expire_page(:controller => 'atom', :action => 'feed')
      expire_page(:controller => 'atom', :action => 'feed', :id => record.id)
      begin
        ppdir = RAILS_ROOT + "/public/atom/feed/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /^(\d+)/
            expire_page(:controller => 'atom', :action => 'feed', :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => %w(index rdf_recent articles_long category_tree_list_a sitemap))

      expire_page(:controller => 'notes', :action => 'recent_trigger_title_a')
      begin
        ppdir = RAILS_ROOT + "/public/notes/recent_trigger_title_a"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\w+).html/
            expire_page(:controller => 'notes', :action => 'recent_trigger_title_a', :trigger => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => 'recent_category_title_a')
      begin
        ppdir = RAILS_ROOT + "/public/notes/recent_category_title_a"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\w+).html/
            expire_page(:controller => 'notes', :action => 'recent_category_title_a', :category => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => 'noteslist')
      begin
        ppdir = RAILS_ROOT + "/public/notes/d/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\d+).html/
            expire_page(:controller => 'notes', :action => 'noteslist', :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => 'articles_author', :id => record.author_id)
      begin
        ppdir = RAILS_ROOT + "/public/notes/articles_author/#{record.author_id}/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\d+).html/
            expire_page(:controller => 'notes', :action => 'articles_author', :id => record.author_id, :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => 'articles_long')
      begin
        ppdir = RAILS_ROOT + "/public/notes/articles_long/d/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\d+).html/
            expire_page(:controller => 'notes', :action => 'articles_long', :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => %w(rdf_article show_title), :id => record.id)
      expire_page(:controller => 'notes', :action => %w(show_enrollment), :id => record.enrollment_id) if record.enrollment_id
      expire_page(:controller => 'notes', :action => %w(rdf_article show_title2), :title => record.title)

      clall = Category.find_all
      clall.each do |rc|
        expire_page(:controller => 'notes', :action => %w(rdf_category show_category show_category_noteslist) , :category => rc.name)

        begin
          ppdir = RAILS_ROOT + "/public/notes/rdf_category/#{rc.name}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'rdf_category', :page => $1, :category => rc.name)
            end
          end
        rescue Errno::ENOENT
        rescue
          p $!
        end
        begin
          ppdir = RAILS_ROOT + "/public/notes/category/#{rc.name}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'category', :page => $1, :category => rc.name)
            end
          end
        rescue Errno::ENOENT
        rescue 
          p $!
        end

        begin
          ppdir = RAILS_ROOT + "/public/notes/show_category/#{rc.id}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'show_category', :page => $1, :id => rc.id)
            end
          end
        rescue Errno::ENOENT
        rescue 
          p $!
        end

        begin
          ppdir = RAILS_ROOT + "/public/notes/d/#{rc.name}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'show_category_noteslist', :page => $1, :category => rc.name)
            end
          end
        rescue Errno::ENOENT
        rescue 
          p $!
        end

      end

      expire_page(:controller => 'notes', :action => 'show_month', :year => record.article_date.year, :month => record.article_date.month)
      expire_page(:controller => 'notes', :action => 'show_nnen', :day => record.article_date.day, :month => record.article_date.month)
      expire_page(:controller => 'notes', :action => 'show_date', :day => record.article_date.day, :month => record.article_date.month, :year => record.article_date.year)

    when Category
      expire_page(:controller => 'notes', :action => 'category_select_a')
      expire_page(:controller => 'notes', :action => 'category_tree_list_a')
    when Comment
      expire_for(record.article)
    when Trackback
      expire_for(record.article)
    when Picture
      expire_for(record.article)
    when Enrollment
      expire_for(record.article)
    end

  end

end
