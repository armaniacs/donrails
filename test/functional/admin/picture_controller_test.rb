require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/picture_controller'

# Re-raise errors caught by the controller.
class Admin::PictureController; def rescue_action(e) raise e end; end

class Admin::PictureControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::PictureController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_manage_picture
    @request.session['person'] = 'ok'
    post :manage_picture
    assert_response 200
  end
  def test_manage_picture_1
    post :manage_picture
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
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
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end

  def test_edit_picture
    @request.session['person'] = 'ok'
    @request.env["HTTP_REFERER"] = __FILE__
    post :edit_picture
    assert_response :redirect
  end
  def test_edit_picture_1
    post :edit_picture
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end
  def test_edit_picture_2
    @request.session['person'] = 'ok'
    @request.env["HTTP_REFERER"] = __FILE__
    p2 = {:id => 12345}
    assert_raise ActiveRecord::RecordNotFound do
      post :edit_picture, :picture => p2
    end
  end

  def test_edit_picture_3
    @request.session['person'] = 'ok'
    @request.env["HTTP_REFERER"] = __FILE__
    p2 = {:id => 1, :aid => '1'}
    post :edit_picture, :picture => p2
    assert_response :redirect
  end

  def test_edit_picture_4
    @request.session['person'] = 'ok'
    @request.env["HTTP_REFERER"] = __FILE__
    p2 = {:id => 1, :body => 'test body'}
    post :edit_picture, :picture => p2
    assert_response :redirect
  end

  def test_delete_picture
    @request.session['person'] = 'ok'
    post :delete_picture
    assert_redirected_to :controller => 'admin/picture', :action => 'manage_picture'
  end
  def test_delete_picture_1
    post :delete_picture
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end
  def test_delete_picture_2
    @request.session['person'] = 'ok'
    post :delete_picture, 
    :filedeleteid => {'1' => '1'}
    assert_equal "<br>Delete File:1", flash[:note2]
    assert_redirected_to :controller => 'admin/picture', :action => 'manage_picture'

    post :delete_picture, 
    :filedeleteid => nil,
    :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :controller => 'admin/picture', :action => 'manage_picture'

    post :delete_picture, 
    :filedeleteid => nil,
    :deleteid => nil,
    :hideid => {'2' => '0'}
    assert_equal "<br>Hyde status:2 is 0", flash[:note2]
    assert_redirected_to :controller => 'admin/picture', :action => 'manage_picture'

    post :delete_picture, 
    :hideid => {'2' => '1'}
    assert_equal "<br>Hyde status:2 is 1", flash[:note2]
    assert_redirected_to :controller => 'admin/picture', :action => 'manage_picture'
  end


  def test_picture_save
    @request.session['person'] = 'ok'
    post :picture_save
    assert_response 403
  end

end
