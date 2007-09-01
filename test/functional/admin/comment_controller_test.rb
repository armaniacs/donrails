require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/comment_controller'

# Re-raise errors caught by the controller.
class Admin::CommentController; def rescue_action(e) raise e end; end

class Admin::CommentControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::CommentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
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

end
