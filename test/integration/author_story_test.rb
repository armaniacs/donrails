require "#{File.dirname(__FILE__)}/../test_helper"

class AuthorStoryTest < ActionController::IntegrationTest
  fixtures :articles, :blogpings, :comments, :don_pings, :authors, :categories, :plugins, :banlists, :don_attachments, :trackbacks, :don_envs, :don_rbls, :enrollments, :dona_daas

  def test_login__fail
    reset!
    get '/author/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/author/author_login_index', path

    post '/author/authenticate', 
    :nz => {"n" => 'testuser', "p" => 'wrongpass'},
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    assert_equal 302, status
    follow_redirect!
    assert_equal '/author/author_login_index', path
  end

  def test_login
    reset!
    get '/author/manage_article'
    assert_equal 302, status
    follow_redirect!
    assert_equal '/author/author_login_index', path

    post '/author/authenticate', 
    :nz => {"n" => 'araki', "p" => 'pass'},
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    follow_redirect!
    assert_equal '/author/new_article', path

    post '/author/delete_article',
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    assert_redirected_to :controller => 'author', :action => 'manage_article'

    post '/author/delete_article', :hideid => {'4' => '0'},
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    assert_redirected_to :action => 'manage_article'

    post '/author/delete_article', :hideid => {'4' => '1'},
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    assert_redirected_to :action => 'manage_article'

    post '/author/delete_article', :deleteid => {'1' => '1'},
    :session_id_validation => Digest::MD5.hexdigest(request.session_options[:id])
    assert_redirected_to :action => 'manage_article'
    
  end

end
