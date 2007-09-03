# A set of security extensions for preventing CSRF
#
# =Example
#
# The following is an example of ensuring all POST requests in an application are secure and that
# the UserController#logout method can only be called by POST.
#
# /app/controllers/application.rb:
#
#   class ApplicationController < ActionController::Base
#     verify_form_posts_have_security_token
#     ...
#   end
#
# /app/controllers/user_controller.rb:
#   class UserController < ApplicationController
#     verify_post :only => :logout
#     ...
#   end
#
# /app/views/layouts/application.rhtml:
#
#   <%= secure_form_tag :action => 'logout' %>
#
#
# /test/functional/user_controller_test.rb:
#
#   def test_should_contain_a_secure_form
#     get :index
#     assert_number_of_secure_forms 1
#   end
#
#   def test_should_require_secure_post
#     post_without_security :logout
#     assert_response 403
#   end
#
#   def test_should_require_post
#     get :logout
#     assert_response 403
#   end
#
#   def test_should_redirect_to_login_on_logout
#     post :logout
#     assert_redirected_to :action => 'login'
#   end

# $Id$
# $URL$

require 'digest/md5'

module SecurityExtensionsPlugin
  module ActionController #:nodoc:
    module Base #:nodoc:
      def self.included(base)        
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          helper_method :security_token
        end
      end

      module ClassMethods #:nodoc:
        # Creates a before filter to check that the user's session id matches that passed into
        # +params+. By combining this with ActionView::Helpers::FormHelper#secure_form_tag you can
        # help prevent CSRF.
        #
        # Based upon the code by Shugo Maeda:
        # http://blog.shugo.net/articles/2005/08/06/prevent-csrf
        #
        # Example usage:
        #   def MySecureController < ActionController::Base
        #     verify_form_posts_have_security_token :only => [:create, :update, :destroy]
        #     def create
        #     ...
        #   end
        #
        # In the +create+ view you'd then replace any calls to +form_tag+ with +secure_form_tag+.
        #
        # +secure_form_tag+ is a complete drop-in replacement for form_tag, so it supports all the
        # same parameters.
        #
        # == Testing
        # To ease testing, all unit testing +post+ calls are automatically made secure. To perform
        # a post without the security token (e.g. for testing security) you can call
        # +post_without_security+ as below:
        #   post_without_security
        #
        # The following test helper method may be useful for testing that posts are secure:
        #   def assert_post_is_secure(action, session = nil)
        #     post_without_security(action, nil, session)
        #     assert_response 403
        #   end
        #
        # which can be used like so:
        #   def test_should_secure_forms
        #     assert_post_is_secure :login
        #     assert_post_is_secure :logout, { :user_id => 1 }
        #   end
        #
        # The options parameter is a hash which may contain the following (optional) keys:
        # * <tt>:only:</tt> only apply this verification to the actions specified in the associated array (may also be a single value)
        # * <tt>:except:</tt> do not apply this verification to the actions specified in the associated array (may also be a single value).
        def verify_form_posts_have_security_token(options = {})
          class_eval do
            before_filter :validate_post_is_secure, :only => options[:only], :except => options[:except]
          end
        end

        # Creates a before filter that ensures the given actions are only requested through a +POST+
        # request.
        #
        # Example usage:
        #   def MySecureController < ActionController::Base
        #     verify_post :only => [:update, :destroy]
        #     def update
        #     ...
        #   end
        #
        # == Testing
        # An example of testing that the +destroy+ method only allows +POST+ requests:
        #   def test_post_verifications
        #     get :destroy
        #     assert_response 403
        #   end
        def verify_post(options = {})
          class_eval do
            before_filter :validate_request_is_post, :only => options[:only], :except => options[:except]
          end
        end
      end

      module InstanceMethods #:nodoc:
        STATUS_403_RESPONSE = '<html><head><title>403 Forbidden</title></head><body><h1>403 Forbidden</h1></body></html>'

        # Filter that checks +POST+ requests for a +session_id_validation+ key
        def validate_post_is_secure
          if request.get? or @params[:session_id_validation] == security_token
            return true
          else
            render(:text => STATUS_403_RESPONSE, :status => '403 Forbidden')
            return false 
          end
        end

        # Filter the checks that the the request is using the +POST+ method
        def validate_request_is_post
          if not request.post?
            render(:text => STATUS_403_RESPONSE, :status => '403 Forbidden')
            return false
          end
        end
      
        def security_token
          Digest::MD5.hexdigest(session.session_id)
        end
      end
    end
  end

  module ActionView #:nodoc:
    module Helpers #:nodoc:
      module FormHelper #:nodoc:
        # Returns a form containing a hidden field with the user's session id. This
        # method can be used in place of the regular +form_tag+ helper.
        # By combining this with ActionController::Verification::ClassMethods#verify_secure_post you
        # can help prevent CSRF.
        #
        # Based upon the code by Shugo Maeda:
        # http://blog.shugo.net/articles/2005/08/06/prevent-csrf
        #
        # Example usage:
        #   <%= secure_form_tag :action => 'create' %>
        def secure_form_tag(*args)
          return start_form_tag(*args) + "\n" +
            hidden_field_tag('session_id_validation', security_token)
        end
        alias :start_secure_form_tag :secure_form_tag
      end
    end
  end
end