ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.

  map.connect '', :controller => "notes", :action => "noteslist", :page => '1'
  map.connect "archives/", :controller => "notes",  :action => "noteslist" , :page => '1'
  map.connect "archives/index", :controller => "notes",  :action => "noteslist" , :page => '1'

  map.connect "archives/noteslist", :controller => "notes",  :action => "noteslist" , :page => '1'
  map.connect "archives/noteslist/page/:page", :controller => "notes", :action => "noteslist", :page => /\d+/

  map.connect "archives/articles_author/:id", :controller => "notes", :action => "articles_author", :id => /\d+/, :page => '1'
  map.connect "archives/articles_author/:id/page/:page", :controller => "notes", :action => "articles_author",
  :requirements => { 
    :id => /\d+/,
    :page => /\d+/
  }

  map.connect "archives/category_articles/:id", 
  :controller => "notes", :action => "show_category_noteslist",
  :page => '1', :requirements =>{:id => /\d+/}
  map.connect "archives/category_articles/:id/page/:page", 
  :controller => "notes", :action => "show_category_noteslist", 
  :requirements => {:id => /\d+/, :page => /\d+/}

  map.connect "archives/show_category_noteslist/:category", 
  :controller => "notes", :action => "show_category_noteslist", 
  :page => '1', :requirements => {:category => /\w+/}
  map.connect "archives/show_category_noteslist/:category/page/:page", 
  :controller => "notes", :action => "show_category_noteslist", 
  :requirements => {:category => /\w+/, :page => /\d+/}

  map.connect "archives/:year/:month/:day", :controller => "notes", 
  :action => "show_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "archives/:year/:month", :controller => "notes", 
  :action => "show_month",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/
  }

  map.connect "archives/hnf/:year/:month/:day", :controller => "notes", 
  :action => "hnf_save_date",
  :requirements => { 
    :year => /(19|20)\d\d/,
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.connect "archives/id/:id", :controller => "notes", 
  :action => "show_enrollment",
  :requirements => { 
    :id => /\d+(\.html)?/
  }

#  map.connect "archives/show_title/:title", :controller => "notes", 
#  :action => "show_title", :title => /.+/

  # for backward compatibility
  map.connect "archives/pick_article/:id", :controller => "notes", 
  :action => "show_title",
  :requirements => { 
    :id => /\d+/
  }

  map.connect "archives/afterday/:ymd2", :controller => "notes", 
  :action => "afterday", :ymd2 => /\d\d\d\d-\d\d-\d\d/
  map.connect "archives/tendays/:ymd2", :controller => "notes", 
  :action => "tendays", :ymd2 => /\d\d\d\d-\d\d-\d\d/

  map.connect "archives/category/:category", 
  :controller => "notes", 
  :action => "show_category", :category => /\w+(\.html)?/, :page => '1'
  map.connect "archives/category/:category/page/:page", 
  :controller => "notes", 
  :action => "show_category", :category => /\w+/, :page => /\d+/

  map.connect "archives/show_category/:id", :controller => "notes", 
  :action => "show_category", :page => '1',
  :requirements => { 
    :id => /\d+/
  }
  map.connect "archives/show_category/:id/page/:page", :controller => "notes", 
  :action => "show_category", 
  :requirements => { 
    :id => /\d+/, :page => /\d+/
  }

  map.connect "archives/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /(\d|-)+/
  }

  map.connect "archives/:nums", :controller => "notes", 
  :action => "indexabc",
  :requirements => { 
    :nums => /\d{6}(a|b|c).html/
  }

  map.connect "archives/:nums", :controller => "notes", 
  :action => "parse_nums",
  :requirements => { 
    :nums => /\S+.html/
  }

  map.connect "archives/every_year/:month/:day", :controller => "notes", 
  :action => "show_nnen",
  :requirements => { 
    :month => /[01]?\d/,
    :day => /[0-3]?\d/
  }

  map.xml 'rdf/rdf_recent/feed.xml', :controller => 'rdf', :action => "rdf_recent"
  map.xml 'rdf/rdf_article/:id/feed.xml', :controller => 'rdf', :action => "rdf_article", :id => /\d+/
  map.xml 'rdf/rdf_enrollment/:id/feed.xml', :controller => 'rdf', :action => "rdf_enrollment", :id => /\d+/
  map.xml 'rdf/rdf_search/:q/feed.xml', :controller => 'rdf', :action => "rdf_search", :q => /.+/
  map.xml 'rdf/rdf_category/:category/feed.xml', :controller => 'rdf', :action => "rdf_category", :category => /\w+/, :page => '1'
  map.xml 'rdf/rdf_category/:category/page/:page/feed.xml', :controller => 'rdf', :action => "rdf_category", :category => /\w+/, :page => /\d+/

  map.xml 'rdf/rss2_recent/feed.xml', :controller => 'rdf', :action => "rss2_recent"
  map.xml 'rdf/rss2_article/:id/feed.xml', :controller => 'rdf', :action => "rss2_article", :id => /\d+/
  map.xml 'rdf/rss2_enrollment/:id/feed.xml', :controller => 'rdf', :action => "rss2_enrollment", :id => /\d+/
  map.xml 'rdf/rss2_search/:q/feed.xml', :controller => 'rdf', :action => "rss2_search", :q => /.+/
  map.xml 'rdf/rss2_category/:category/feed.xml', :controller => 'rdf', :action => "rss2_category", :category => /\w+/, :page => '1'
  map.xml 'rdf/rss2_category/:category/page/:page/feed.xml', :controller => 'rdf', :action => "rss2_category", :category => /\w+/, :page => /\d+/

  map.connect 'archives/recent_category_title_a/:category', :controller => 'notes', :action => "recent_category_title_a", :category => /\w+/
  map.connect 'archives/recent_trigger_title_a/:trigger', :controller => 'notes', :action => "recent_trigger_title_a", :trigger => /\w+/

  map.connect "archives/articles_long", :controller => "notes", :action => "articles_long", :page => '1'
  map.connect "archives/articles_long/page/:page", :controller => "notes", :action => "articles_long", :page => /\d+/

  map.xml 'atom/feed.xml', :controller => 'atom', 
  :action => "feed", :page => '1'
  map.xml 'atom/feed/page/:page/feed.xml', :controller => 'atom', 
  :action => "feed", :page => /\d+/
  map.xml 'atom/feed/:aid/feed.xml', :controller => 'atom', :action => "feed", :aid => /\d+/

  map.xml 'archives/sitemap.xml', :controller => 'notes', :action => "sitemap"

  map.connect 'archives/:action/:id', :controller => 'notes'

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
