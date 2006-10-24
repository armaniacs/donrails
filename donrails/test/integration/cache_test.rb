require "#{File.dirname(__FILE__)}/../test_helper"

class CacheTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :pings, :authors, :categories, :plugins, :banlists, :pictures, :trackbacks, :don_envs, :don_rbls, :enrollments

  # Replace this with your real tests.
  def test_truth
    assert true
  end


  # http://www.cosinux.org/~dam/projects/page-cache-test/doc/files/README.html
  def test_caching_notes
    #caches_page :index, :rdf_recent, :rdf_article, :rdf_category, :show_month, :show_nnen, :show_date, :show_category, :show_category_noteslist, :articles_long, :noteslist, :category_select_a, :recent_trigger_title_a, :recent_category_title_a, :category_tree_list_a, :articles_author, :sitemap, :show_enrollment

    assert_cache_pages("/")
    assert_cache_pages("/archives/id/1","/archives/id/2","/archives/id/4","/archives/id/10","/archives/id/11")
    assert_cache_pages("/rdf/rdf_enrollment/1/feed.xml", 
                       '/rdf/rdf_recent/feed.xml',
                       '/rdf/rdf_article/1/feed.xml')
    assert_cache_pages('/archives/1999/1', '/archives/1999/1/1')
    assert_cache_pages('/archives/every_year/1/1')

    assert_expire_pages('/archives','/archives/id/1', 
                        '/archives/pick_article/1',
                        '/rdf/rdf_recent/feed.xml',
                        '/rdf/rdf_article/1/feed.xml',
                        '/rdf/rdf_enrollment/1/feed.xml',
                        '/archives/1999/1',
                        '/archives/1999/1/1',
                        '/archives/every_year/1/1',
                        '/archives'
                        ) do |*urls|
      c = {"author" => "testauthor", "password" => "hoge5", 
        "url" => "http://localhost/test.html", 
        "title" => "testtitle", 
        "body" => "testbody", "article_id" => 1}
      post '/archives/add_comment2', :comment => c, :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    end

    assert_cache_pages('/rdf/rdf_category/misc/feed.xml')
#    assert_cache_pages('/archives/1999/01/01')

  end


  def test_login
  end
end
