require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/enrollment_controller'

# Re-raise errors caught by the controller.
class Admin::EnrollmentController; def rescue_action(e) raise e end; end

class Admin::EnrollmentControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::EnrollmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
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
