# The methods added to this helper will be available to all templates in the application.

require 'delegator'
require 'donplugin'
require 'time'
require 'jcode'

require 'rexml/document'
require 'cgi'

require 'base64'
require 'fileutils'

module ApplicationHelper

=begin rdoc

=== ApplicationHelper#don_supported_formats

=end

  def don_supported_formats
    return DonRails::DataFormatDelegator.formatlist
  end # def don_supported_formats

=begin rdoc

=== ApplicationHelper#don_get_object(obj, type)

=end

  def don_get_object(obj, type)
    return DonRails::DataFormatDelegator.new(obj, type)
  end # def don_get_object

=begin rdoc

== ApplicationHelper#don_chomp_tags(text)

=end

  def don_chomp_tags(text)
    if text.nil? then
      return ""
    else
      return text.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end
  end # def don_chomp_tags

  def pub_date(time)
    time.iso8601
  end

=begin rdoc

=== ApplicationHelper#don_insert_stylesheet_link_tags

=end

  def don_get_stylesheets
    DonRails::Plugin.stylesheets
  end # def don_get_stylesheets

=begin rdoc

=== ApplicationHelper#don_mb_truncate(text, length = 30, truncate_string = "...")

=end

  def don_mb_truncate(text, length = 30, truncate_string = "...")
    text = text.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    retval = text

    return "" if text.nil?
    mbtext = text.each_char
    if mbtext.length > length then
      retval = mbtext[0..(length - truncate_string.length)].join + truncate_string
    end

    return retval
  end # def don_mb_truncate

=begin

=== ApplicationHelper#don_get_theme(name)

=end

  def don_get_theme(name)
    theme = don_get_config.default_theme
    path = File.dirname(name)
    filename = File.basename(name)
    if path && theme && filename
      return File.join(path, theme, filename)
    elsif path && filename
      return File.join(path, filename)
    elsif filename
      return File.join(filename)
    end
  end # def don_get_theme

  def article_url(article, only_path = true)
    url_for :only_path => only_path, 
    :controller=>"notes", 
    :action =>"show_title", 
    :id => article.id
  end
  
  def sendping(article, blogping)
    articleurl = article_url(article, false)
    urllist = Array.new

    blogping.each do |ba|
      urllist.push(ba.server_url)
    end
    if urllist.size > 0
      article.send_pings2(articleurl, urllist)
    end
  end

  def parsecontent(databody)
    if databody =~ (/^<content(.*)<\/content>/im)
      doc = REXML::Document.new(databody)
      elems = doc.root.elements
      elems.each("pre") do |elem|
        if elem.to_s =~ (/^<pre>(.*)<\/pre>$/m)
          elem_escape = CGI.escapeHTML(CGI.unescapeHTML($1))
        end
        e = REXML::Element.new("pre")
        e.add_text(elem_escape)
        elems[elems.index(elem)] = e
      end
      databody = doc.to_s
    end
    cdb = databody.sub(/^<content \w+='.+'/, "<content")
    if cdb =~ /^<content>(.*)<\/content>/m
      databody = $1
    end
    return databody
  end

  def bind_article_category(article, category)
    cat1 = category.split(' ')
    cat1.each do |cat|
      aris3 = Category.find(:first, :conditions => ["name = ?", cat])
      if aris3
        article.categories.push_with_attributes(aris3)
      else
        aris2 = Category.new("name" => cat)
        aris2.save
        article.categories.push_with_attributes(aris2)
      end
    end
  end

  # rfc4287 atom:entry
  #           atomAuthor*
  #           & atomCategory*
  #           & atomContent?
  #           & atomContributor*
  #           & atomId
  #           & atomLink*
  #           & atomPublished?
  #           & atomRights?
  #           & atomSource?
  #           & atomSummary?
  #           & atomTitle
  #           & atomUpdated
  #           & extensionElement
  def atom_update_article2(article, raw_post)
    xml = REXML::Document.new(raw_post)
    databody = String.new

    # atomAuthor # XXX

    # atomCategory* 
    #    atomCategory =
    #      element atom:category {
    #        atomCommonAttributes,
    #        attribute term { text },
    #        attribute scheme { atomUri }?,
    #        attribute label { text }?,
    #        undefinedContent
    #      }

    if xml.root.elements['category']
      if xml.root.elements['category'].text
        bind_article_category(article, xml.root.elements['category'].text)
      elsif xml.root.elements['category'].attributes["term"]
        cat1 = String.new
        xml.root.each_element("category") do |elem|
          cat1 += elem.attributes['term']
          cat1 += ' '
        end
        bind_article_category(article, cat1)
      end
    end

    if xml.root.elements['content'].attributes["type"] == "text/html"
      article.format = "html"
    elsif xml.root.elements['content'].attributes["type"] == "text/plain"
      article.format = "plain"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-hnf"
      article.format = "hnf"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-rd"
      article.format = "rd"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-wiliki"
      article.format = "wiliki"
    else
      article.format = "html" # default
    end

    # atomContent?
    if xml.root.elements['content'].attributes["mode"] == "escaped"
      databody = '<content>' + CGI.unescapeHTML(xml.root.elements['content'].text) + '</content>'
    else
      databody = xml.root.elements['content'].to_s
    end
    article.body = parsecontent(databody)
    article.size = article.body.size

    # atomContributor* # XXX
    # atomLink* # XXX
    # atomPublished? # XXX
    # atomRights? # XXX
    # atomSource? # XXX atom:entry is copied from one feed into another feed
    # atomSummary? # XXX

    #  atomTitle
    if xml.root.elements['title'].text
      article.title = xml.root.elements['title'].text
    elsif xml.root.elements['title'].to_s
      if xml.root.elements['title'].to_s =~ (/^<title>(.+)<\/title>$/)
        article.title = $1
      end
    end

    # atomUpdated
    if xml.root.elements['updated'] and xml.root.elements['updated'].text
      article.article_mtime = xml.root.elements['updated'].text
    else
      article.article_mtime = Time.now
    end

    # extensionElement
    if xml.root.elements['articledate'] and xml.root.elements['articledate'].text
      article.article_date = xml.root.elements['articledate'].text
    else
      article.article_date = Time.now
    end

    blogping = Blogping.find(:all, :conditions => ["active = 1"])
    if blogping and blogping.size > 0
      sendping(article, blogping)
    end
  end
  

  def atom_parse_image(image, raw_post)
    xml = REXML::Document.new(raw_post)
    databody = String.new
    filetype = ''
    suffix = 'gif'
    t1 = Time.now

    if xml.root.elements['relateid']
      ida = xml.root.elements['relateid'].text.split(':')
      if ida[0] == 'tag' and ida[1] == @request.host and ida[2] == 'notes'
        image.article_id = ida[3].to_i
      end
    end

    image.content_type = xml.root.elements['content'].attributes["type"]
    if image.content_type =~ /image\/(.+)$/i
      if $1 =~ /(jpeg|jpg)/i
        suffix = 'jpg'
      elsif $1 =~ /(gif)/i
        suffix = 'gif'
      elsif $1 =~ /(png)/i
        suffix = 'png'
      else
        suffix = $1
      end
      image.name = t1.to_i.to_s + '-' + raw_post.size.to_s + '.' + suffix
    end

    if xml.root.elements['content'].attributes['mode'] == 'base64'
      image_data = Base64.decode64(xml.root.elements['content'].text)
    end

    dumpdir = File.expand_path(RAILS_ROOT) + IMAGE_DUMP_PATH + t1.year.to_s + '-' + t1.month.to_s + '-' + t1.day.to_s + '/'
    unless File.directory? dumpdir
      FileUtils.makedirs dumpdir
    end
    image.path = dumpdir + image.name
    f = File.new(image.path, "w")
    image.size = f.write(image_data)
    f.close
  end

  def display_categories_roots_ul(categories, manage=nil)
    content = ''
    if categories.size > 0
      content = '<ul>'
      categories.each do |category|
        content += '<li>' + link_to(category.name, {:controller => 'notes', :action => :show_category, :id => category.id}) 
        if manage
          content += '[' + link_to('管理', {:controller => 'login', :action => :manage_category, :id => category.id}) + ']'
        end
        content += '(' + category.articles.size.to_s + ')'
        content += display_categories_roots_ul(category.direct_children, manage)
        content += '</li>'
      end
      content += '</ul>'
    end
    return content
  end

  def display_categories_roots_ul_description(categories,depth=0)
    content = ''
    i = 0
    if categories.size > 0
      content = '<ul>'
      categories.each do |category|
        i += 1
        content += '<li>' + link_to(category.name, {:controller => 'notes', :action => :show_category, :id => category.id}) 
        content += '(' + category.articles.size.to_s + ')'
        content += ' / ' + category.description if category.description
        if depth > i
          content += display_categories_roots_ul_description(category.direct_children)
        end
        content += '</li>'
      end
      content += '</ul>'
    end
    return content
  end
  
  def display_article_date(article)
    if article and article.article_date
    content = link_to "#{article.article_date.year}年#{article.article_date.month}月#{article.article_date.day}日(#{article.article_date.strftime('%a')})",
         {:action => "show_date",
          :year => article.article_date.year,
          :month => article.article_date.month,
          :day => article.article_date.day
         }
    end
  end

  def display_article_categories(article)
    content = ''
    article.categories.each do |cat|
      begin
        if cat.name
          content += '[' + link_to(cat.name, {:action => "show_category", :id => cat.id}) + ']'
        end
      rescue
      end
    end
    return content
  end

  def display_article_attachments(article)
    content = ''
    article.don_attachments.each do |atta|
      if atta.format
        content += render("shared/attachments/#{atta.format}", "atta" => atta)
      else
        content += render("shared/attachments/picture", "atta" => atta)
      end
    end
    return content
  end
  alias :display_article_images :display_article_attachments

  def display_enrollment_images(enrollment)
    content = ''
    enrollment.articles.each do |article|
      content += display_article_attachments(article)
    end
    return content
  end

  def don_get_config
    begin
      de = DonEnv.find(:first, :conditions => ["hidden IS NULL OR hidden = 0"])
      if de == nil
        de = don_get_oldconfig 
      end
    rescue
      de = don_get_oldconfig
    end
    return de
  end

  def don_get_oldconfig
    de = DonEnv.new
    de.image_dump_path = IMAGE_DUMP_PATH if defined?(IMAGE_DUMP_PATH)
    de.admin_user = ADMIN_USER if defined?(ADMIN_USER)
    de.admin_password = ADMIN_PASSWORD if defined?(ADMIN_PASSWORD)
    de.rdf_title = RDF_TITLE if defined?(RDF_TITLE)
    de.rdf_description = RDF_DESCRIPTION if defined?(RDF_DESCRIPTION)
    de.rdf_copyright = RDF_COPYRIGHT if defined?(RDF_COPYRIGHT)
    de.rdf_managingeditor = RDF_MANAGINGEDITOR if defined?(RDF_MANAGINGEDITOR)
    de.rdf_webmaster = RDF_WEBMASTER if defined?(RDF_WEBMASTER)
    de.baseurl = defined?(BASEURL) ? BASEURL : ''
    de.admin_mailadd = ADMIN_MAILADD if defined?(ADMIN_MAILADD)
    de.default_theme = defined?(DEFAULT_THEME) ? DEFAULT_THEME : 'default'
    de.trackback_enable_time = TRACKBACK_ENABLE_TIME if defined?(TRACKBACK_ENABLE_TIME)
    return de
  end
  
  def don_get_ip_rbl
    rblhosts = Array.new
    DonRbl.find(:all, :conditions => ["rbl_type = 'ip'"]).each do |dr|
      rblhosts.push(dr.hostname)
    end
    return rblhosts
  end

  def don_get_host_rbl
    rblhosts = Array.new
    DonRbl.find(:all, :conditions => ["rbl_type = 'host'"]).each do |dr|
      rblhosts.push(dr.hostname)
    end
    return rblhosts
  end

end
