module RdfHelper
  def rdf_parts10(xmlorig)
    xml = Builder::XmlMarkup.new(:target => xmlorig)
    xml.instruct! :xml, :version=>"1.0", :encoding => "utf-8"
    xml.instruct! :rss, :version=>"1.0"
    return xmlorig
  end

  def rdf_parts21(xmlorig, article=nil, action=nil, query=nil)
    xml = Builder::XmlMarkup.new(:target => xmlorig)
    xml.title don_get_config.rdf_title
    if article && action && query
      xml.link(request.protocol + request.host_with_port + 
               url_for(:controller =>'notes', :action => action,
                       :q => query))
    elsif article && action
      xml.link(request.protocol + request.host_with_port + 
               url_for(:controller =>'notes', :action => action,
                       :id => article.id))
    elsif article
      xml.link(request.protocol + request.host_with_port + 
               url_for(:controller =>'notes', :action => "show_title", 
                       :id => article.id))
    else
      xml.link(request.protocol + request.host_with_port)
    end
    xml.description don_get_config.rdf_description
    return xmlorig
  end


  def rdf_parts23(xmlorig, item, action)
    xml = Builder::XmlMarkup.new(:target => xmlorig)

    if action == "show_enrollment" and item.class.to_s == "Enrollment"
      xml.rdf(:li, "rdf:resource"=> "#{request.protocol}#{request.host_with_port}#{url_for(:controller => 'notes', :action => action, :id => item.id)}")
    elsif action == "show_enrollment"
      xml.rdf(:li, "rdf:resource"=> "#{request.protocol}#{request.host_with_port}#{url_for(:controller => 'notes', :action => action, :id => item.enrollment_id)}")
    else
      xml.rdf(:li, "rdf:resource"=> "#{request.protocol}#{request.host_with_port}#{url_for(:controller => 'notes', :action => action, :id => item.id)}")
    end
    return xmlorig
  end

  def rdf_parts31(xmlorig, item, action)
    xml = Builder::XmlMarkup.new(:target => xmlorig)

    if action == "show_enrollment"
      xml.link(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.enrollment_id))
    elsif action == "show_title"
      xml.link(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.id))
    end

    categories = Array.new
    item.categories.each do |cat|
      categories.push cat.name
      xml.tag!("dc:subject") do
        xml.text! cat.name
      end
    end
    title_line = ''
    categories.each do |cn|
      title_line += '[' + cn + ']'
    end
    title_line += ' ' + item.title_to_xml
    xml.title(title_line)

    begin
      ce = item.body_to_xml
      xml.comment!(item.format)
      if ce =~ (/^<html xmlns='http:\/\/www.w3.org\/1999\/xhtml'><body>(.*)<\/body><\/html>$/m)
        ce = $1
      end    
      if ce =~ (/<content>(.*)<\/content>/m)
        ce = $1
      end    
      xml.tag!("description") do
        xml << ce.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
      end
      xml.tag!("content:encoded") do
        xml.cdata! ce
      end    
    rescue
      print "Error: #{$!} in #{item.id}\n"
    end
    
    if item.article_mtime
      xml.tag!("dc:date") do
        xml.text! "#{pub_date(item.article_mtime)}"
      end
    end
    item.pictures.each do |pic|
      tmpurl1 = request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => "show_image", :id => pic.id)
      xml.image(:item, "rdf:about"=> tmpurl1)
    end
    return xmlorig
  end

  def rss2_parts21(xmlorig, article=nil, action=nil, query=nil)
    xml = Builder::XmlMarkup.new(:target => xmlorig)
    rdf_parts21(xml, article, action, query)
    xml.language "ja"
    xml.pubDate Time.new.rfc2822
    xml.docs "http://blogs.law.harvard.edu/tech/rss"
    xml.generator "donrails"
    xml.copyright don_get_config.rdf_copyright
    return xmlorig
  end

  def rss2_parts31(xmlorig, item, action)
    xml = Builder::XmlMarkup.new(:target => xmlorig)

    if action == "show_enrollment"
      xml.link(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.enrollment_id))
      xml.guid(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.enrollment_id))
    elsif action == "show_title"
      xml.link(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.id))
      xml.guid(request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => action, :id => item.id))
    end

    item.categories.each do |cat|
      xml.category cat.name
    end

    categories = Array.new
    item.categories.each do |cat|
      categories.push cat.name
      xml.tag!("dc:subject") do
        xml.text! cat.name
      end
    end
    title_line = ''
    categories.each do |cn|
      title_line += '[' + cn + ']'
    end
    title_line += ' ' + item.title_to_xml
    xml.title(title_line)

    begin
      ce = item.body_to_xml
      if ce =~ (/^<html xmlns='http:\/\/www.w3.org\/1999\/xhtml'><body>(.*)<\/body><\/html>$/m)
        ce = $1
      end    
      if ce =~ (/<content>(.*)<\/content>/m)
        ce = $1
      end    
      xml.description do
        xml.cdata! ce
      end    
    rescue
      print "Error: #{$!} in #{item.id}\n"
    end

    if item.article_mtime
      xml.pubDate item.article_mtime.rfc2822
    end

    item.pictures.each do |pic|
      tmpurl1 = request.protocol + request.host_with_port + url_for(:controller => 'notes', :action => "show_image", :id => pic.id)
      xml.enclosure("url"=> tmpurl1)
    end

    return xmlorig
  end

end
