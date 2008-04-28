require File.dirname(__FILE__) + '/../test_helper'
require 'author_controller'

class AuthorControllerTest < ActionController::TestCase
  def setup
    @controller = AuthorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  # Replace this with your real tests.

  def test_author_authorize
    post :author_authorize
    assert_response :redirect
    assert_redirected_to :action => :author_login_index
  end

  def test_author_login_index
    post :author_login_index
    true
  end

  def test_authenticate
    get :authenticate
    assert_response :redirect
    assert_redirected_to :action => :author_login_index

    c = Hash.new
    c["n"] = "araki"
    c["p"] = "pass"
    post :authenticate, :nz => c
    assert_response :redirect
    assert_redirected_to :action => :new_article

    c = Hash.new
    c["n"] = "araki"
    c["p"] = "pass"
    get :authenticate, :nz => c
    assert_response :redirect
    assert_redirected_to :action => :author_login_index
  end

  def test_logout
    get :logout
    assert_response :redirect
    assert_redirected_to :action => :author_login_index
  end

  def test_add_article
    @request.session["author"] = 'ok'
    c1 = Hash.new
    c1["title"] = "test title"
    c1["body"] = "test body"
    c2 = Hash.new
    c2['name'] = "araki"
    post :add_article, :article => c1, :author => c2
    assert_redirected_to :action => :manage_article

    c3 = Hash.new
    c3['preview'] = 1
    post :add_article, :article => c1, :author => c2, :preview => c3
    assert_redirected_to :action => :preview_article

    # errors
    c2 = Hash.new
    c2['name'] = "araki-nonexist"
    post :add_article, :article => c1, :author => c2
    assert_response :error
    assert_match "Non-regist", @response.body

    post :add_article, :article => c1
    assert_response :error
    assert_match "invalid entry", @response.body
  end

  def test_form_article
    @request.session["author"] = 'ok'
    post :form_article, :id => 1
    assert_response :success
    post :preview_article, :id => 1
    assert_response :success

    post :form_article, :id => 10000
    assert_response :missing
    post :preview_article, :id => 10000
    assert_response :missing
  end

  def test_preview_article_confirm
    @request.session["author"] = 'ok'
    c1 = Hash.new
    c1["id"] = 1

    post :preview_article_confirm, :commit => 'create', :article => c1
    assert_redirected_to :action => :manage_article
  end

  def test_manage_article
    @request.session["author"] = 'ok'
    post :manage_article, nil, nil, {:author_name => 'araki'}
    assert_match "4 sendmail", @response.body

    post :manage_article, {:nohidden => '1'}, nil, {:author_name => 'araki'}
    assert_no_match /4 sendmail/, @response.body
  end

  def test_fix_article 
    @request.session["author"] = 'ok'
    c1 = Hash.new
    c1["id"] = 1
    c1["title"] = "fix title of 1"
    c1["body"] = "fix body of 1"
    c2 = Hash.new
    c2["1"] = "1"
    c3 = Hash.new
    c3["preview"] = 1

    post :fix_article, {:article => c1, :newid => c2}, nil, {:author_name => 'araki'}
    assert_redirected_to :action => :manage_article

    post :fix_article, {:article => c1, :newid => c2, :preview => c3}, nil, {:author_name => 'araki'}
    assert_redirected_to :action => :preview_article

    c1["referer"] = "/author/index"
    post :fix_article, {:article => c1, :newid => c2}, nil, {:author_name => 'araki'}
    assert_match /%2Fauthor%2Findex/, @response.headers["Location"]

  end

  def test_delete_article
    @request.session["author"] = 'ok'
    c1 = Hash.new
    c1["1"] = 1

    post :delete_article, {:deleteid => c1}, nil, {:author_name => 'araki'}
    assert_redirected_to :action => :manage_article

  end

end
