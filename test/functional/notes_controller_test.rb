require File.dirname(__FILE__) + '/../test_helper'
require 'notes_controller'

# Re-raise errors caught by the controller.
class NotesController; def rescue_action(e) raise e end; end

class NotesControllerTest < Test::Unit::TestCase
  def setup
    @controller = NotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  def test_trackback
    @request.env['skip_akismet'] = true

    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text excerpt text',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'
    
    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    assert_match require_response_body, @response.body
  end

  def test_trackback_1a
    @request.env['skip_akismet'] = true

    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text excerpt text',
    :url => "https://test.example.com/blog/",
    :blog_name => 'test of donrails'
    
    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    assert_match require_response_body, @response.body
  end

  def test_trackback__2
    @request.env['skip_akismet'] = true
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt evil text sex',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    assert_match(/<error>1/, @response.body)
    assert_response 403
  end

  def test_trackback__3
    @request.env['skip_akismet'] = true
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text excerpt text',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    assert_match require_response_body, @response.body

  end

  def test_trackback__akismet
    post :trackback,
    :id => 1,
    :title => 'viagra-test-123',
    :excerpt => 'this comment_author triggers known spam',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    assert_match(/<error>1/, @response.body)
    assert_response 403

  end

  def test_trackback__too_old
    @request.env['skip_akismet'] = true
    post :trackback,
    :id => 100,
    :title => 'title test util',
    :excerpt => 'this is trackback of too old article',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    assert_match(/<error>1/, @response.body)
    assert_response 403
  end


  def test_index
    if don_get_config.default_theme.to_s == 'MT' || (defined?(DEFAULT_THEME) && DEFAULT_THEME == 'MT')
    else
      get :index
      assert_response :success
    end
  end

  def test_search
    get :search, :q => 'sendmail'
    assert_response :success
  end

  def test_show_search_noteslist
    get :search, :q => 'sendmail'
    assert_response :success
  end
  

  def test_pick_article_a
    get :pick_article_a, :pickid => 1
    assert_response :success
  end
  def test_pick_article_a2
    get :pick_article_a2, :pickid => 1
    assert_response :success

    get :pick_article_a2, :eid => 1
    assert_response :success
  end

  def test_comment_form_a
    get :comment_form_a, :id => 1
    assert_response :success
  end
  def test_articles_long
    get :articles_long
    assert_response :success
  end
  def test_indexabc
    get :indexabc, :nums => '200401a'
    assert_redirected_to :controller => 'notes', :action => 'tendays', :year => '2004', :month => '01', :day => '01'
    get :indexabc, :nums => '200401a.html'
    assert_redirected_to :controller => 'notes', :action => 'tendays', :year => '2004', :month => '01', :day => '01'

    get :indexabc, :nums => '200401b'
    assert_redirected_to :controller => 'notes', :action => 'tendays', :year => '2004', :month => '01', :day => '11'

    get :indexabc, :nums => '200401c'
    assert_redirected_to :controller => 'notes', :action => 'tendays', :year => '2004', :month => '01', :day => '21'

    get :indexabc, :nums => '20040105c'
    assert_response 404
  end

  def test_noteslist
    get :noteslist
    assert_response 200
  end

  def test_parse_nums
    get :parse_nums
    assert_response 302
  end
  def test_parse_nums__1
    get :parse_nums, :nums => '200403051'
    assert_response 302
    assert_match(/notice=200403051/, @response.headers['Location'])
  end
  def test_parse_nums__2
    get :parse_nums, :nums => '20040305'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end
  def test_parse_nums__3
    get :parse_nums, :nums => '2004-03-05'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end

  def test_parse_nums__5
    get :parse_nums, :nums => '20040305.html'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end
  def test_parse_nums__6
    get :parse_nums, :nums => '2004-03-06.html'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '06', :month => '03'
  end

  def test_recent_trigger_title_a
    get :recent_trigger_title_a, :trigger => 'recents'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'trackbacks'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'comments'
    assert_response :success
    get :recent_trigger_title_a, :trigger => 'long'
    assert_response :success
  end

  def test_recent_category_title_a
    get :recent_category_title_a, :category => 'misc'
    assert_response :success

    get :recent_category_title_a, :category => 'null'
    assert_response :success
  end

  def test_category_select_a
    get :category_select_a
    assert_response :success
  end

  def test_show_month 
    get :show_month ,:year => 1979, :month => 01
    assert_response 404
  end


  def test_show_month__2
    get :show_month ,:year => 1999, :month => 01
    assert_response 200
  end

  def test_show_month__3
    get :show_month ,:day => 31, :month => 01
    assert_response 404
    get :show_month , :month => 01
    assert_response 404
  end



  def test_show_nnen
    get :show_nnen ,:day => 01, :month => 01
    assert_response 200
  end

  def test_show_date
    get :show_date ,:day => 01, :month => 01, :year => 1999
    assert_response 200
  end
  def test_show_date__2
    get :show_date ,:day => 31, :month => 01, :year => 2009
    assert_response 302
  end

  def test_show_title
    get :show_title, :id => 1
    assert_response 200
    get :show_title, :pickid => 1
    assert_redirected_to :action => 'show_title', :id => 1
  end 


  def test_show_title__2 # XXX
    get :show_title, :title => 2
  end 
  def test_show_title__3
    get :show_title, :title => 'first title in misc'
    assert_redirected_to :controller => 'notes', :id => 1
    assert_redirected_to :action => 'show_title', :id => 1
  end 
  def test_show_title__4
    get :show_title, :id =>10000
    assert_response 404
  end
  def test_show_title__5
    get :show_title
    assert_response 404
  end
  def test_show_title__6
    get :show_title, :inchiki => nil
    assert_response 404
  end

  def test_show_category
    get :show_category, :category => 'misc'
    assert_response 200

    get :show_category, :id => 1
    assert_response 200

    get :show_category, :nocategory => 'misc'
    assert_response 200
  end
  def test_show_category__2
    get :show_category, :category => 'miscmisc'
    assert_response 404
  end
  def test_show_category__3
    get :show_category, :cat => 'nil'
    assert_response 404
  end
  def test_show_category_noteslist
    get :show_category_noteslist, :category => 'misc'
    assert_response 200
  end
  def test_show_category_noteslist__2
    get :show_category_noteslist, :category => 'miscmisc'
    assert_response 404
  end
  def test_show_category_noteslist__3
    get :show_category_noteslist, :catgory => 'miscmisc'
    assert_response 404
  end

  def test_afterday
    get :afterday, :ymd2 => '1999-01-01'
    assert_response 200
  end

  def test_afterday__2
    get :afterday, :ymd2 => '2036-12-05'
    assert_response 404
  end

  def test_tendays
    get :tendays, :ymd2 => '1999-01-01'
    assert_response 200
  end
  def test_tendays__2
    get :tendays, :ymd2 => '2017-12-05'
    assert_response 404
  end

  def test_add_comment2
    @request.env['skip_akismet'] = true
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "donrails", 
      "body" => "this is donrails test", "article_id" => 1}
    post :add_comment2, :comment => c

    assert_match(/^http:\/\/test.host\/archives\/\w+\/1/, @response.headers['Location'])

    assert_response 302
  end

  def test_add_comment2__too_short
    @request.env['skip_akismet'] = true
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "123", "article_id" => 1}
    post :add_comment2, :comment => c
    assert_match('Body is too short (minimum is 5 characters)', @response.body)
    assert_response 403
  end

  def test_add_comment2__spam
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "sex sex sex", "article_id" => 1}
    post :add_comment2, :comment => c
    assert_response 403
    assert_match(/blocked by|Temporary failure/, @response.body)
  end

  # get is not valid request.
  def test_add_comment2_1
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 1}

    get :add_comment2, :comment => c
    assert_response 302
  end

  def test_catch_ping
    post :catch_ping, :category => 'misc', :blog_name => 'test blog',
    :title => 'test title', :excerpt => 'test excerpt', :url => 'http://localhost/test/blog'
    assert_response :success
  end

  def test_show_image
    get :show_image, :id => 1
    assert_response :redirect

    get :show_image, :id => 2
    assert_response 403

    get :show_image, :id => '1&qoot'
    assert_response :redirect
  end

  def test_sitemap
    get :sitemap
    assert_response :success
  end

  def test_pick_enrollment_a
    get :pick_enrollment_a, :pickid => 10
    assert_response :success
    assert_match(/ireko\d+/, @response.body)
    assert_match(/excerpt test tb in fixture/, @response.body)
  end


end
