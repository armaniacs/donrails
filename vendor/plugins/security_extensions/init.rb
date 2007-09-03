# $Id$
# $URL$

require 'security_extensions'
ActionController::Base.send(:include, SecurityExtensionsPlugin::ActionController::Base)
ActionView::Base.send(:include, SecurityExtensionsPlugin::ActionView::Helpers::FormHelper)

if RAILS_ENV == 'test'
  require 'security_testing_extensions'
  Test::Unit::TestCase.send(:include, SecurityExtensionsPlugin::Test::Unit::TestCase)
end
