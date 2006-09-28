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
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text excerpt text',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    assert_equal require_response_body, @response.body
  end

  def test_trackback__2
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt evil text sex',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>1</error>\n  <message>count:1</message>\n</response>\n"
    assert_response :success
    assert_equal require_response_body, @response.body
  end

  def test_trackback__3
    post :trackback,
    :id => 1,
    :title => 'title test util',
    :excerpt => 'excerpt text excerpt text',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>0</error>\n  <message>success</message>\n</response>\n"
    assert_response :success
    assert_equal require_response_body, @response.body
  end

#   def test_trackback__too_short_excerpt
#     post :trackback,
#     :id => 1,
#     :title => 'title test util',
#     :excerpt => 'too short',
#     :url => "http://test.example.com/blog/",
#     :blog_name => 'test of donrails'

#     require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>1</error>\n  <message>count:1</message>\n</response>\n"
#     assert_response :success
#     assert_equal require_response_body, @response.body
#   end

  def test_trackback__too_old
    post :trackback,
    :id => 100,
    :title => 'title test util',
    :excerpt => 'this is trackback of too old article',
    :url => "http://test.example.com/blog/",
    :blog_name => 'test of donrails'

    require_response_body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n  <error>1</error>\n  <message>count:1</message>\n</response>\n"
    assert_response :success
    assert_equal require_response_body, @response.body
  end


  def test_index
    if defined?(DEFAULT_THEME) and DEFAULT_THEME == 'MT'
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

=begin
  def test_dateparse
    get :dateparse, {'200607a' => ''}
    assert_redirected_to :action => "tendays", :year => '2006', :month => '07', :day => "01"
    get :dateparse, {'200607b' => ''}
    assert_redirected_to :action => "tendays", :year => '2006', :month => '07', :day => "11"
    get :dateparse, {'200607c' => ''}
    assert_redirected_to :action => "tendays", :year => '2006', :month => '07', :day => "21"

    get :dateparse, {'0601' => ''}
    assert_redirected_to :action => "show_nnen", :month => '06', :day => "01"
    get :dateparse, {'1213' => ''}
    assert_redirected_to :action => "show_nnen", :month => '12', :day => "13"
  end
=end

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
    assert_match(/notice=200403051/, @response.headers['location'])
  end
  def test_parse_nums__2
    get :parse_nums, :nums => '20040305'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end
  def test_parse_nums__3
    get :parse_nums, :nums => '2004-03-05'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end
#  def test_parse_nums__4
#    get :parse_nums, :nums => '2004-3-05'
#    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
#  end
  def test_parse_nums__5
    get :parse_nums, :nums => '20040305.html'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '05', :month => '03'
  end
  def test_parse_nums__6
    get :parse_nums, :nums => '2004-03-06.html'
    assert_redirected_to :controller => 'notes', :year => '2004', :day => '06', :month => '03'
  end

  def test_rdf_recent
    get :rdf_recent
    assert_response :success
  end

  def test_rdf_article
    get :rdf_article, :id => 1
    assert_response :success

    get :rdf_article
    assert_response :missing

    get :rdf_article, :id => 4
    assert_response :missing

    get :rdf_article, :id => 444444
    assert_response :missing
  end

  def test_rdf_enrollment
    get :rdf_enrollment, :id => 1
    assert_response :success

    get :rdf_enrollment
    assert_response :missing

    get :rdf_enrollment, :id => 444444
    assert_response :missing
  end

  def test_rdf_search
    get :rdf_search, :q => 'sendmail'
    assert_response :success
  end

  def test_rdf_category
    get :rdf_category, :category => 'no category'
    assert_response 302

    get :rdf_category, :category => 'misc'
    assert_response :success
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
#    assert_response 404
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
    get :afterday, :ymd2 => '2016-12-05'
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
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 1}
    post :add_comment2, :comment => c
    assert_match(/^http:\/\/test.host\/notes\/\w+\/1/, @response.headers['location'])
    assert_response 302

    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "123", "article_id" => 1}
    post :add_comment2, :comment => c
    assert_match('Body is too short (minimum is 5 characters)', @response.body)
    assert_response 403
  end

  # get is not valid request.
  def test_add_comment2_1
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 1}

    get :add_comment2, :comment => c
#    assert_equal('http://test.host/notes/d', @response.headers['location'])
    assert_response 302
  end

  def test_add_comment2_not
    c = {"author" => "testauthor", "password" => "hoge5", 
      "url" => "http://localhost/test.html", 
      "title" => "testtitle", 
      "body" => "testbody", "article_id" => 1}

    post_without_security :add_comment2, :comment => c
    assert_response 403
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
