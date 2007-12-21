require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/article_controller'

# Re-raise errors caught by the controller.
class Admin::ArticleController; def rescue_action(e) raise e end; end

class Admin::ArticleControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::ArticleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
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

    assert_redirected_to :action => 'manage_author'

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


  def test_new_article
    @request.session['person'] = 'ok'
    post :new_article
    assert_response 200
  end
  def test_new_article_1
    post :new_article
    assert_redirected_to :action => 'login_index'
  end

end
