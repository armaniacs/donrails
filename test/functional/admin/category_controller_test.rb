require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/category_controller'

# Re-raise errors caught by the controller.
class Admin::CategoryController; def rescue_action(e) raise e end; end

class Admin::CategoryControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::CategoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end


  def test_manage_category
    @request.session['person'] = 'ok'
    post :manage_category
    assert_response 200
  end
  def test_manage_category_1
    post :manage_category
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end

  def test_add_category
    @request.session['person'] = 'ok'
    post :add_category
        assert_redirected_to :controller => 'admin/category', :action => 'manage_category'
    assert_equal "", flash[:note] 

    post :add_category, :category => {:parent_name => 'misc', :name => 'misc child'}
        assert_redirected_to :controller => 'admin/category', :action => 'manage_category'
    assert_equal "Add new category:misc child. Her parent is misc.", flash[:note]

    post :add_category, :category => {:name => 'misc child2'}
        assert_redirected_to :controller => 'admin/category', :action => 'manage_category'
    assert_equal "Add new category:misc child2.", flash[:note]

    post :add_category, :category => {:parent_name => 'none', :name => 'orphan'}
        assert_redirected_to :controller => 'admin/category', :action => 'manage_category'
    assert_equal "Add new category:orphan.", flash[:note]
  end

  def test_add_category_1
    post :add_category
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end

  def test_delete_category
    @request.session['person'] = 'ok'
    post :delete_category
        assert_redirected_to :controller => 'admin/category', :action => 'manage_category'
  end
  def test_delete_category_1
    post :delete_category
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end

end
