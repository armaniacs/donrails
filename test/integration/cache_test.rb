require "#{File.dirname(__FILE__)}/../test_helper"

class CacheTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :don_pings, :authors, :categories, :plugins, :banlists, :don_attachments, :trackbacks, :don_envs, :don_rbls, :enrollments

  def test_caching_fix_article
    reset!
    get '/admin/article/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/admin/login/login_index', path

    post '/admin/login/authenticate',
    :nz => {"n" => 'testuser', "p" => 'testpass'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    follow_redirect!
    assert_equal '/admin/article/manage_article', path

    post '/admin/article/fix_article',
    :article => {
      :title => 'test fix article title', 
      :body => 'body and soul',
      :id => 1
    },
    :newid => {:id => 1},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    follow_redirect!
    assert_equal '/admin/article/manage_article', path    

    assert_expire_pages(
                        '/archives/pick_article/1',
                        '/archives'
                        ) do |*urls|
      post '/admin/article/fix_article',
      :article =>{
        "article_date"=>"2026-09-26", "title"=>"fixtest", 
        "body"=>"this is a test body. (fixtest)\r\nfix at 5/10\r\nひるめしひるめし\r\n電子レンジ\r\nどうよ\r\nnanidana\r\n", 
        "tburl"=>"", "id"=>"1", "author_id"=>"1"
      },
      "format"=>"plain", "commit"=>"save", "category"=>{"name"=>""}, 
      "author"=>{"name"=>"araki"}, "action"=>"fix_article", 
      "controller"=>"admin/article", 
      "hideid"=>{"1"=>"0"}, 
      "preview"=>{"preview"=>"0"}, 
      :article => {
        :title => 'test fix article title', 
        :body => 'body and soul2.1',
        :id => 1
      },
      :newid => {"1" => 0},
      :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)

    end
    follow_redirect!
    assert_equal '/admin/article/manage_article', path    

  end


  # http://www.cosinux.org/~dam/projects/page-cache-test/doc/files/README.html
  def test_caching_notes
    #caches_page :index, :rdf_recent, :rdf_article, :rdf_category, :show_month, :show_nnen, :show_date, :show_category, :show_category_noteslist, :articles_long, :noteslist, :category_select_a, :recent_trigger_title_a, :recent_category_title_a, :category_tree_list_a, :articles_author, :sitemap, :show_enrollment

    assert_cache_pages("/")
    assert_cache_pages("/archives/id/1","/archives/id/2","/archives/id/4","/archives/id/10","/archives/id/11")
    assert_cache_pages("/rdf/rdf_enrollment/1/feed.xml", 
                       '/rdf/rdf_article/1/feed.xml')
    assert_cache_pages('/feed.xml')

    assert_cache_pages('/archives/1999/1', '/archives/1999/1/1')
    assert_cache_pages('/archives/every_year/1/1')

    assert_cache_pages('/archives/show_category_noteslist/misc')
    assert_cache_pages('/archives/category_articles/1')

    assert_cache_pages('/archives/recent_trigger_title_a',
                       '/archives/recent_trigger_title_a/recents',
                       '/archives/recent_trigger_title_a/trackbacks',
                       '/archives/recent_trigger_title_a/comments',
                       '/archives/recent_trigger_title_a/long')

    assert_expire_pages('/archives/id/1', 
                        '/archives/pick_article/1',

                        '/archives/noteslist',
                        '/archives/recent_category_title_a',

                        '/archives/recent_trigger_title_a',
                        '/archives/recent_trigger_title_a/recents',
                        '/archives/recent_trigger_title_a/trackbacks',
                        '/archives/recent_trigger_title_a/comments',
                        '/archives/recent_trigger_title_a/long',

                        # '/rdf/rdf_recent/feed.xml',
                        '/feed.xml',

                        '/archives/articles_long',
                        '/archives/category_tree_list_a',
                        # '/archives/sitemap.xml',
                        '/sitemap.xml',
                        '/rdf/rdf_article/1/feed.xml',
                        '/rdf/rdf_category/misc/page/1/feed.xml',
                        '/rdf/rdf_category/misc/feed.xml',
                        '/rdf/rss2_category/misc/page/1/feed.xml',
                        '/rdf/rss2_category/misc/feed.xml',
                        '/archives/pick_article/1',
                        '/archives/id/1',
                        '/rdf/rdf_enrollment/1/feed.xml',
                        '/archives/1999/1',
                        '/archives/1999/1/1',
                        '/atom/feed.xml',
                        '/atom/feed/page/1/feed.xml',

                        '/archives/every_year/1/1',
                        '/archives'
                        ) do |*urls|
      c = {"author" => "testauthor", "password" => "hoge5", 
        "url" => "http://localhost/test.html", 
        "title" => "testtitle", 
        "body" => "testbody in cache_test", "article_id" => 1}
      post '/archives/add_comment2', :comment => c, :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    end
    follow_redirect!
    assert_equal '/archives/id/1', path    
#    assert_cache_pages('/rdf/rdf_category/misc/feed.xml')
  end


  def test_caching_notes_scn
    assert_cache_pages('/archives/show_category_noteslist/misc')
    assert_cache_pages('/archives/category_articles/1/page/1')

    assert_expire_pages(
                        '/archives/category_articles/1/page/1',
                        '/archives/show_category_noteslist/misc/page/1'
                        ) do |*urls|
      c = {"author" => "testauthor", "password" => "hoge5", 
        "url" => "http://localhost/test.html", 
        "title" => "testtitle", 
        "body" => "testbody in cache_test", "article_id" => 1}
      post '/archives/add_comment2', :comment => c, :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    end
    follow_redirect!
    assert_equal '/archives/id/1', path    
  end

end
