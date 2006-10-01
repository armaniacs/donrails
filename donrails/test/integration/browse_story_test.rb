require "#{File.dirname(__FILE__)}/../test_helper"

class BrowseStoryTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :pings, :authors, :categories, :plugins, :banlists, :pictures, :trackbacks

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_fromtop
    if defined?(DEFAULT_THEME) && DEFAULT_THEME == 'MT'
    else
      get "/notes/index"
      assert_equal 200, status
    end
    get "/notes"
    assert_equal 200, status

    get "/notes/search", :q => 'first body'
    assert_equal 200, status

    get "/notes/show_search_noteslist", :q => 'first body'
    assert_equal 200, status

    get "/notes/pick_trackback_a", :pickid => '1'
    assert_equal 200, status

    get "/notes/pick_comment_a", :pickid => '1'
    assert_equal 200, status

    get "/notes/199901a.html"
    assert_equal 302, status

    get_via_redirect "/notes/199901a.html"
    assert_equal 200, status

    # http://donrails.araki.net/notes/show_category/47?page=3
    get '/notes/show_category/47?page=3'
    assert_equal 404, status
#    p @response.headers
    get '/notes/show_category/1?page=1'
    assert_equal 200, status
    get '/notes/show_category/1/page/1'
    assert_equal 200, status

    # GET /notes/category/misc/page/108?article_date=.html    
  end
end
