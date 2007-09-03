# Extensions to Test::Unit to help functional testing of controller for CSRF attacks.

# $Id$
# $URL$

require 'action_controller/test_process'
require 'digest/md5'

module SecurityExtensionsPlugin #:nodoc:
  module Test #:nodoc:
    module Unit #:nodoc:
      module TestCase #:nodoc:
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.class_eval do
            alias_method :post_without_security, :post
            alias_method :post, :post_with_security
          end
        end        
        
        module InstanceMethods #:nodoc:
          # Performs a POST request without passing a valid security token
          def post_with_security(action, parameters = nil, session = nil, flash = nil)
            parameters ||= {}
            parameters.update(:session_id_validation => Digest::MD5.hexdigest(@request.session.session_id))
            post_without_security(action, parameters, session, flash)
          end
          
          # Asserts that the response contains the specified number of secure forms
          def assert_number_of_secure_forms(count)
            form_tags = find_all_tag(:tag => 'form', :attributes => { :method => 'post' })
            assert_equal form_tags.length, count, 'Number of (POST) forms does not match'
            form_tags.each do |formtag|
              hidden_secure_tag = formtag.find(:tag => 'input', :attributes => { :type => 'hidden', :id => 'session_id_validation' })
              assert hidden_secure_tag, 'Form does not contain secure session key'
              assert_equal hidden_secure_tag.attributes['value'], Digest::MD5.hexdigest(@request.session.session_id), 'Secure session key does not match'
            end
          end
        end
      end
    end
  end
end
