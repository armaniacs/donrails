require File.dirname(__FILE__) + '/../test_helper'
require 'rdf_controller'

# Re-raise errors caught by the controller.
class RdfController; def rescue_action(e) raise e end; end

class RdfControllerTest < Test::Unit::TestCase
  def setup
    @controller = RdfController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
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

end
