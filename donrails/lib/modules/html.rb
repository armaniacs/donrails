=begin

=HTML file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>
 Copyright (C) 2005 ARAKI Yasuhiro <araki@araki.net>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'cgi'
require 'htree'

module DonRails

=begin rdoc

== DonRails::HTML

=end

  module HTML
    include DonRails::PlainText

=begin rdoc

=== DonRails::HTML#title_to_html

=end
    
    def title_to_html
      retval = self.to_s
      if self.to_s =~ (/\A(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
        retval = sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
      end
      
      return retval
    end # def title_to_html

=begin rdoc

=== DonRails::HTML#title_to_xml

=end

    def title_to_xml
      return self.title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def title_to_xml

=begin rdoc

=== DonRails::HTML#body_to_html

=end

    def body_to_html
      return self.to_s
    end # def body_to_html

=begin rdoc

=== DonRails::HTML#body_to_xml

=end

    def body_to_xml
      begin
        bth = '<html><body>' + self.body_to_html + '</body></html>'
        xml = HTree.parse(bth).to_rexml
        return xml.to_s
      rescue
        return self.to_s
      end
    end # def body_to_xml

  end # module HNF

end # module DonRails
