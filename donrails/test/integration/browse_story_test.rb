require "#{File.dirname(__FILE__)}/../test_helper"

class BrowseStoryTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :don_pings, :authors, :categories, :plugins, :banlists, :pictures, :trackbacks, :don_envs, :don_rbls, :enrollments

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_login
    get '/login/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/login/login_index', path

    post '/login/authenticate', :nz => {"n" => 'testuser', "p" => 'testpass'}, :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    follow_redirect!
    assert_equal '/login/manage_article', path
  end

  def test_fromtop
    if don_get_config.default_theme == 'MT'
    else
      get "/archives/index"
      assert_equal 200, status
    end
    get "/notes"
    assert_equal 200, status

    get "/archives/search", :q => 'first body'
    assert_equal 200, status

    get "/archives/show_search_noteslist", :q => 'first body'
    assert_equal 200, status

    get "/archives/pick_trackback_a", :pickid => '1'
    assert_equal 200, status

    get "/archives/pick_comment_a", :pickid => '1'
    assert_equal 200, status

    get "/archives/199901a.html"
    assert_equal 302, status

    get_via_redirect "/archives/199901a.html"
    assert_equal 200, status

    # http://donrails.araki.net/archives/show_category/47?page=3
    get '/archives/show_category/47?page=3'
    assert_equal 404, status
#    p @response.headers
    get '/archives/show_category/1?page=1'
    assert_equal 200, status
    get '/archives/show_category/1/page/1'
    assert_equal 200, status

    get '/archives/category/misc'
    assert_equal 200, status
    get '/archives/category/misc.html'
    assert_equal 200, status

    # GET /archives/category/misc/page/108?article_date=.html    
  end

end
