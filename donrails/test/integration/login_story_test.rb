require "#{File.dirname(__FILE__)}/../test_helper"

class LoginStoryTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :don_pings, :authors, :categories, :plugins, :banlists, :pictures, :trackbacks, :don_envs, :don_rbls, :enrollments

  # Replace this with your real tests.
  def test_truth
    assert true
    reset!
  end

  def test_login__fail
    reset!
    get '/login/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/login/login_index', path

    post '/login/authenticate', 
    :nz => {"n" => 'testuser', "p" => 'wrongpass'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    assert_equal 302, status
    follow_redirect!
    assert_redirected_to :action => 'login_index'
  end

  def test_login
    reset!
    get '/login/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/login/login_index', path

    post '/login/authenticate', 
    :nz => {"n" => 'testuser', "p" => 'testpass'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    follow_redirect!
    assert_equal '/login/manage_article', path

    post '/login/delete_article',
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    assert_redirected_to :action => 'manage_article'

    post '/login/delete_article', :hideid => {'4' => '0'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    assert_redirected_to :action => 'manage_article'

    post '/login/delete_article', :hideid => {'4' => '1'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    assert_redirected_to :action => 'manage_article'

    post '/login/delete_article', :deleteid => {'1' => '1'},
    :session_id_validation => Digest::MD5.hexdigest(request.session.session_id)
    assert_redirected_to :action => 'manage_article'
    
  end

end
