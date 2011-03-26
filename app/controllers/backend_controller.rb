require 'actionwebservice'

class BackendController < ApplicationController
  cache_sweeper :article_sweeper
##  session :off ## comment in 2.3.2

  web_service_dispatching_mode :layered
  web_service_exception_reporting false

  web_service(:metaWeblog)  { MetaWeblogService.new(self) }
  web_service(:mt)          { MovableTypeService.new(self) }
  web_service(:blogger)     { BloggerService.new(self) }
  web_service(:weblogUpdates) { DonWebService.new(self) }

##  alias xmlrpc api
end
