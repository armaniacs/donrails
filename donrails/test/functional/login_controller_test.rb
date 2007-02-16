require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  def setup
    @controller = LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_login_index
    get :login_index
    assert_response 200
  end

  def test_authenticate
    post :authenticate, :nz => {:n => 'testuser', :p => 'testpass'}
    assert_redirected_to :action => 'new_article'
  end
  def test_authenticate__fail
    post :authenticate, :nz => {:n => 'testuser', :p => 'wrongpass'}
    assert_response(403)
  end


  def test_new_article
    @request.session['person'] = 'ok'
    post :new_article
    assert_response 200
  end
  def test_new_article_1
    post :new_article
    assert_redirected_to :action => 'login_index'
  end

  def test_logout
    @request.session['person'] = 'ok'
    post :logout
    assert_redirected_to :action => 'login_index'
  end

  def test_manage_category
    @request.session['person'] = 'ok'
    post :manage_category
    assert_response 200
  end
  def test_manage_category_1
    post :manage_category
    assert_redirected_to :action => 'login_index'
  end

  def test_add_category
    @request.session['person'] = 'ok'
    post :add_category
    assert_redirected_to :action => 'manage_category'
    assert_nil flash[:note] 

    post :add_category, :category => {:parent_name => 'misc', :name => 'misc child'}
    assert_redirected_to :action => 'manage_category'
    assert_equal "Add new category:misc child. Her parent is misc.", flash[:note]

    post :add_category, :category => {:name => 'misc child2'}
    assert_redirected_to :action => 'manage_category'
    assert_equal "Add new category:misc child2.", flash[:note]

    post :add_category, :category => {:parent_name => 'none', :name => 'orphan'}
    assert_redirected_to :action => 'manage_category'
    assert_equal "Add new category:orphan.", flash[:note]
  end

  def test_add_category_1
    post :add_category
    assert_redirected_to :action => 'login_index'
  end

  def test_delete_category
    @request.session['person'] = 'ok'
    post :delete_category
    assert_redirected_to :action => 'manage_category'
  end
  def test_delete_category_1
    post :delete_category
    assert_redirected_to :action => 'login_index'
  end

  def test_manage_picture
    @request.session['person'] = 'ok'
    post :manage_picture
    assert_response 200
  end
  def test_manage_picture_1
    post :manage_picture
    assert_redirected_to :action => 'login_index'
  end

  def test_manage_picture_detail
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :manage_picture_detail
    assert_response :redirect

    post :manage_picture_detail, :id => 1
    assert_response :success
  end
  def test_manage_picture_detail_1
    post :manage_picture_detail
    assert_redirected_to :action => 'login_index'
  end

  def test_edit_picture
    @request.session['person'] = 'ok'
    @request.env["HTTP_REFERER"] = __FILE__
    post :edit_picture
    assert_response :redirect
  end
  def test_edit_picture_1
    post :edit_picture
    assert_redirected_to :action => 'login_index'
  end

  def test_delete_picture
    @request.session['person'] = 'ok'
    post :delete_picture
    assert_redirected_to :action => 'manage_picture'
  end
  def test_delete_picture_1
    post :delete_picture
    assert_redirected_to :action => 'login_index'
  end
  def test_delete_picture_2
    @request.session['person'] = 'ok'
    post :delete_picture, 
    :filedeleteid => {'1' => '1'}
    assert_equal "<br>Delete File:1", flash[:note2]
    assert_redirected_to :action => 'manage_picture'

    post :delete_picture, 
    :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_picture'

    post :delete_picture, 
    :hideid => {'2' => '0'}
    assert_equal "<br>Hyde status:2 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_picture'

    post :delete_picture, 
    :hideid => {'2' => '1'}
    assert_equal "<br>Hyde status:2 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_picture'
  end


  def test_picture_save
    @request.session['person'] = 'ok'
    post :picture_save
    assert_response 403
  end

  def test_manage_trackback
    @request.session['person'] = 'ok'
    post :manage_trackback
    assert_response :success 
  end

  def test_delete_trackback
    @request.session['person'] = 'ok'
    post :delete_trackback
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback,
    :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'2' => '0'}
    assert_equal "<br>Hyde status:2 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'2' => '0'}
    assert_equal "<br>Spam status:2 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'2' => '1'}
    assert_equal "<br>Hyde status:2 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'2' => '1'}
    assert_equal "<br>Spam status:2 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'3' => '0'}
    assert_equal "<br>Hyde status:3 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'3' => '1'}
    assert_equal "<br>Hyde status:3 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'3' => '0'}
    assert_equal "<br>Spam status:3 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'3' => '1'}
    assert_equal "<br>Spam status:3 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'
  end

  def test_manage_comment
    @request.session['person'] = 'ok'
    post :manage_comment
    assert_response :success 
  end

  def test_delete_comment
    @request.session['person'] = 'ok'
    post :delete_comment
    assert_redirected_to :action => 'manage_comment'

    post :delete_comment,
    :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_comment'

    post :delete_comment, 
    :hideid => {'3' => '0'}
    assert_equal "<br>Hyde status:3 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_comment'

    post :delete_comment, 
    :hideid => {'3' => '1'}
    assert_equal "<br>Hyde status:3 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_comment'
  end


  def test_form_article
    @request.session['person'] = 'ok'
    post :form_article, :pickid => 1
    assert_response :success 

    post :form_article
    assert_response 404

    post :form_article, :pickid => 111
    assert_response 404
  end

  def test_fix_article
    @request.session['person'] = 'ok'
    post :fix_article
    assert_redirected_to :action => 'manage_article'

    post :fix_article, :article => {:title => 'test fix article title'}
    assert_redirected_to :action => 'manage_article'

    post :fix_article, :article => {:title => 'test fix article title', :id => 1}, :newid => {:id => 3}
    assert_redirected_to :action => 'manage_article'

    post :fix_article, :article => {:title => 'test fix article title', :id => 1}, :newid => {:id => 0}
    assert_redirected_to :action => 'manage_article'

    post :fix_article, :article => {:title => 'test fix article title', :id => 1}, :newid => {:id => 1}
    assert_redirected_to :action => 'manage_article'

    # id 22 を元に新規記事として書く。trackbackを21にむけて出す
    post :fix_article, :article => {:title => 'fixtest + tb', :id => 22, :tburl => 'http://localhost:3000/notes/trackback/5340', :body => 'this a test trackback'}, :newid => {'22' => '1'}
    assert_redirected_to :action => 'manage_article'
  end

  def test_fix_article__1
    @request.session['person'] = 'ok'
    post :fix_article, 
    :article =>{"article_date"=>"2006-11-05", "title"=>"test", "body"=>"これはてすと\r\n{{{\r\n[2006-11-05 23:15:19] INFO  going to shutdown ...\r\n[2006-11-05 23:15:19] INFO  WEBrick::HTTPServer#start done.\r\nYou have new mail
in /var/mail/yaar\r\ncfard3:~/donrails-trunk/rails$ ./script/server -b 0.0.0.0\r\n}}}\r\n", "author_name"=>"araki", "tburl"=>"", "id"=> 1, "author_id"=>"1"}, 
    :commit =>"save", 
    :format =>"wiliki", 
    :category =>{"name"=>"misc3"}, 
    :catname =>{"1"=>"1"},
    :newid => {"1" => '1'}
    assert_redirected_to :action => 'manage_article'
  end

  def test_add_article
    @request.session['person'] = 'ok'
    post :add_article
    assert_response 404

    post :add_article, 
    :article => {:title => 'test add article title', :body => 'body and soul'}, 
    :format => 'plain',
    :category => {:name => 'test misc'},
    :author => {:name => 'test author'}
    assert_response 404
#    assert_redirected_to :action => 'manage_article'

    post :add_article, 
    :article => {:title => 'test add article title', :body => 'body and soul', :tburl => 'http://localhost:3000/notes/trackback/1'}, 
    :format => 'plain',
    :category => {:name => 'test misc'},
    :author => {:name => 'araki2'}
    assert_redirected_to :action => 'manage_article'
  end

  def test_manage_article
    @request.session['person'] = 'ok'
    post :manage_article
    assert_response :success
  end

  def test_delete_article
    @request.session['person'] = 'ok'
    post :delete_article
    assert_redirected_to :action => 'manage_article'

    post :delete_article, :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_article'

    post :delete_article, :deleteid => {'40000' => '1'}
    assert_equal "<br>Not exists (no delete):40000", flash[:note2]
    assert_redirected_to :action => 'manage_article'

    post :delete_article,
    :hideid => {'4' => '0'}
    assert_equal "<br>Hyde status:4 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_article'

    post :delete_article, 
    :hideid => {'4' => '1'}
    assert_equal "<br>Hyde status:4 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_article'

    post :delete_article, 
    :hideid => {'40000' => '1'}
    assert_equal "", flash[:note2]
    assert_redirected_to :action => 'manage_article'
  end

  def test_delete_article__issue33
    @request.session['person'] = 'ok'

    assert_nothing_raised do 
      for i in 50..59
        Article.find(i) 
      end
    end
    post :delete_article, :deleteid => {'59' => '1'}
    assert_equal "<br>Delete:59", flash[:note2]
    assert_redirected_to :action => 'manage_article'
    assert_nothing_raised do 
      for i in 50..58
        Article.find(i) 
      end
    end
    assert_raise(ActiveRecord::RecordNotFound) do  Article.find(59) end

    post :delete_article, :deleteid => {'58' => '1'}
    post :delete_article, :deleteid => {'57' => '1'}
    post :delete_article, :deleteid => {'56' => '1'}
    post :delete_article, :deleteid => {'55' => '1'}
    post :delete_article, :deleteid => {'54' => '1'}
    post :delete_article, :deleteid => {'53' => '1'}
    post :delete_article, :deleteid => {'52' => '1'}
    post :delete_article, :deleteid => {'51' => '1'}

    assert_raise(ActiveRecord::RecordNotFound) do 
      for i in 51..58
        Article.find(i) 
      end
    end
    assert_nothing_raised do 
      for i in 50..50
        Article.find(i) 
      end
    end

  end

  def test_manage_banlist
    @request.session['person'] = 'ok'
    post :manage_banlist
    assert_response :success
  end

  def test_delete_banlist
    @request.session['person'] = 'ok'
    post :delete_banlist
    assert_redirected_to :action => 'manage_banlist'

    post :delete_banlist, :deleteid => {'1' => '1'}
    assert_redirected_to :action => 'manage_banlist'
  end

  def test_add_banlist
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :add_banlist
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => 'test\s+pattern'},
    :format => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => 'test\s+white'},
    :format => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:pattern => 'test\s+white'},
    :format => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:pattern => 'test\s+black', :teststring => 'test black'},
    :format => 'regexp'
    assert_response :redirect
    assert_equal "teststring: \"test black\" is matched pattern: \"test\\s+black\"", flash[:note2]

    post :add_banlist,
    :banlist => {:teststring => 'test black'},
    :format => 'regexp'
    assert_response :redirect
    assert_equal "please input", flash[:note2]
  end

  ## issue29
  def test_add_banlist_ipaddr
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :add_banlist
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => '123.123.123.123'},
    :format => 'ipaddr'
    assert_response :redirect

    post :add_banlist,
    :banlist => {
      "add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1", "teststring"=>"127.0.0.1"},
    :format => 'ipaddr'
    assert_response :redirect

    post :add_banlist,
    :commit =>"\343\203\206\343\202\271\343\203\210", 
    :format =>"ipaddr", 
    :banlist =>{"add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1", "teststring"=>"127.0.0.1"}
    assert_response :redirect

    post :add_banlist,
    :commit =>"\343\203\206\343\202\271\343\203\210", 
    :format =>"ipaddr", 
    :banlist =>{"add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1"}
    assert_response :redirect
  end

  def test_test_banlist
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :test_banlist
    assert_response :redirect

    post :test_banlist,
    :banlist => {:pattern => 'test\s+black'}
    assert_response :redirect
  end

  def test_manage_don_ping
    @request.session['person'] = 'ok'
    post :manage_don_ping
    assert_response :success
  end

  def test_manage_blogping
    @request.session['person'] = 'ok'
    post :manage_blogping
    assert_response :success
  end

  def test_delete_blogping
    @request.session['person'] = 'ok'
    post :delete_blogping
    assert_redirected_to :action => 'manage_blogping'

    post :delete_blogping,
    :acid => {'1' => '1'}
    assert_redirected_to :action => 'manage_blogping'
    assert_equal '[Activate] http://localhost:3000/backend/api<br>', flash[:note]
    
    post :delete_blogping,
    :acid => {'1' => '0'}
    assert_redirected_to :action => 'manage_blogping'
    assert_equal '[Deactivate] http://localhost:3000/backend/api<br>', flash[:note]

    post :delete_blogping,
    :deleteid => {'1' => '1'}
    assert_redirected_to :action => 'manage_blogping'
    assert_equal '[Delete] http://localhost:3000/backend/api<br>', flash[:note]

    post :delete_blogping,
    :deleteid => {'1' => '0'}
    assert_redirected_to :action => 'manage_blogping'
    assert_equal '', flash[:note]
  end

  def test_add_blogping
    @request.session['person'] = 'ok'
    post :add_blogping
    assert_redirected_to :action => 'manage_blogping'

    post :add_blogping,
    :blogping => {:server_url => 'http://example.com/'}
    assert_redirected_to :action => 'manage_blogping'
    assert_equal "[Add] http://example.com/<br>", flash[:note]
  end

  def test_manage_author
    @request.session['person'] = 'ok'
    post :manage_author
    assert_response :success

    post :manage_author, :id => 1
    assert_response :success

  end

  def test_delete_unwrite_author
    @request.session['person'] = 'ok'
    post :delete_unwrite_author
    assert_redirected_to :action => 'manage_author'

    post :delete_unwrite_author,
    :acid => {'1' => '1'}
    assert_redirected_to :action => 'manage_author'

    post :delete_unwrite_author,
    :acid => {'1' => '0'}
    assert_redirected_to :action => 'manage_author'

    post :delete_unwrite_author,
    :deleteid => {'1' => '1'}
    assert_redirected_to :action => 'manage_author'

    post :delete_unwrite_author,
    :deleteid => {'1' => '0'}
    assert_redirected_to :action => 'manage_author'
  end

  def test_add_author
    @request.session['person'] = 'ok'
    post :add_author
    assert_redirected_to :action => 'manage_author'

    post :add_author,
    :author => {:name => 'test author', :pass => 'test pass', :summary => 'test summary'}
    assert_redirected_to :action => 'manage_author'

    post :add_author,
    :author => {:name => 'araki2', :pass => 'test pass', :summary => 'test summary'}
    assert_redirected_to :action => 'manage_author'

  end

  def test_manage_enrollment
    @request.session['person'] = 'ok'
    post :manage_enrollment
    assert_response :success
  end

  def test_delete_enrollment
    @request.session['person'] = 'ok'
    post :delete_enrollment
    assert_redirected_to :action => 'manage_enrollment'

    post :delete_enrollment, :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_enrollment'

    post :delete_enrollment, :deleteid => {'40000' => '1'}
    assert_equal "<br>Not exists:40000", flash[:note2]
    assert_redirected_to :action => 'manage_enrollment'

=begin
    post :delete_enrollment,
    :hideid => {'4' => '0'}
    assert_equal "<br>Hyde status:4 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_enrollment'

    post :delete_enrollment, 
    :hideid => {'4' => '1'}
    assert_equal "<br>Hyde status:4 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_enrollment'

    post :delete_enrollment, 
    :hideid => {'40000' => '1'}
    assert_equal "<br>Not exists:40000", flash[:note2]
    assert_redirected_to :action => 'manage_enrollment'
=end
  end

end
