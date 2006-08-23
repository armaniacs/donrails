ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  map.connect '', :controller => "notes", :action => "index"

  map.connect "notes/", :controller => "notes", :action => "index"

  map.connect "notes/d", :controller => "notes", :action => "noteslist"
  map.connect "notes/d/page/:page", :controller => "notes", :action => "noteslist", :page => /\d+/

  map.connect "notes/articles_author/:id", :controller => "notes", :action => "articles_author",
  :requirements => { 
    :id => /\d+/
  }
  map.connect "notes/articles_author/:id/page/:page", :controller => "notes", :action => "articles_author",
  :requirements => { 
    :id => /\d+/,
    :page => /\d+/
  }


  map.connect "notes/d/:category", :controller => "notes", 
  :action => "show_category_noteslist",
  :requirements => { 
    :category => /.+/
  }
  

  map.connect "notes/:year/:month/:day", :controller => "notes", 
  :action => "show_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "notes/:year/:month", :controller => "notes", 
  :action => "show_month",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/
  }

  map.connect "notes/hnf/:year/:month/:day", :controller => "notes", 
  :action => "hnf_save_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "notes/id/:id", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :id => /\d+/
  }

  map.connect "notes/t/:title", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :title => /\S+/
  }

  # for backward compatibility
  map.connect "notes/pick_article/:id", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :id => /\d+/
  }

  map.connect "notes/afterday/:ymd2", :controller => "notes", 
  :action => "afterday", :ymd2 => /\d\d\d\d-\d\d-\d\d/
  map.connect "notes/tendays/:ymd2", :controller => "notes", 
  :action => "tendays", :ymd2 => /\d\d\d\d-\d\d-\d\d/

  map.connect "notes/category/:category", :controller => "notes", 
  :action => "show_category"
  map.connect "notes/category/:category/page/:page", :controller => "notes", 
  :action => "show_category", :page => /\d+/

  map.connect "notes/show_category/:id/page/:page", :controller => "notes", 
  :action => "show_category", 
  :requirements => { 
    :id => /\d+/, :page => /\d+/
  }

  map.connect "notes/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /^(\d|-)+/
  }

  map.connect "notes/:nums", :controller => "notes", 
  :action => "indexabc",
  :requirements => { 
    :nums => /\d{6}(a|b|c).html/
  }

  map.connect "notes/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /\S+.html/
  }

  map.connect "notes/every_year/:month/:day", :controller => "notes", 
  :action => "show_nnen",
  :requirements => { 
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "notes/search/:q", :controller => "notes", 
  :action => "search",
  :requirements => { 
	:q => /\w+/
  }

  map.xml 'notes/rdf_recent/feed.xml', :controller => 'notes', :action => "rdf_recent"
  map.connect "notes/di.cgi", :controller => "notes", :action => "rdf_recent"

  map.xml 'notes/rdf_article/:id/feed.xml', :controller => 'notes', :action => "rdf_article"

  map.xml 'notes/rdf_category/:category/feed.xml', :controller => 'notes', :action => "rdf_category", :category => /\w+/
  map.xml 'notes/rdf_category/:category/page/:page/feed.xml', :controller => 'notes', :action => "rdf_category", :category => /\w+/, :page => /\d+/

  map.connect "notes/rdf_search/:q", :controller => "notes", 
  :action => "rdf_search",
  :requirements => { 
	:q => /\w+/
  }

  map.connect 'notes/recent_category_title_a/:category', :controller => 'notes', :action => "recent_category_title_a", :category => /\w+/
  map.connect 'notes/recent_trigger_title_a/:trigger', :controller => 'notes', :action => "recent_trigger_title_a", :trigger => /\w+/

  map.connect "notes/articles_long/page/:page", :controller => "notes", :action => "articles_long", :page => /\d+/

  map.xml 'atom/feed.xml', :controller => 'atom', :action => "feed"
  map.xml 'atom/feed/page/:page/feed.xml', :controller => 'atom', :action => "feed", :page => /\d+/
  map.xml 'atom/feed/:id/feed.xml', :controller => 'atom', :action => "feed", :id => /\d+/

  map.xml 'notes/sitemap.xml', :controller => 'notes', :action => "sitemap"

  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "notes"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
