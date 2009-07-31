=begin

=HyperNikkiSystem file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'cgi'

pt = nil
begin
  # require 'hpricot'
  gem 'hpricot'
  pt = 'hpricot'
rescue Exception
  begin
    require 'htree'
    pt = 'htree'
  rescue Exception
    raise 
  end
end
raise unless pt 

module DonRails

=begin rdoc

== DonRails::HNF

=end

  module HNF
    include DonRails::PlainText

=begin rdoc

=== DonRails::HNF#title_to_html

=end
    
    def title_to_html
      retval = self.to_s
      if self.to_s =~ (/\A(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
        retval = sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
      end
      
      return retval
    end # def title_to_html

=begin rdoc

=== DonRails::HNF#title_to_xml

=end

    def title_to_xml
      return self.title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def title_to_xml

=begin rdoc

=== DonRails::HNF#body_to_html

=end

    def body_to_html
      retval = ""

      pre_tag = false
      self.to_s.split(/\r\n|\r|\n/).each do |line|
        if line =~ (/\APRE/) then
          retval << '<pre>'
          pre_tag = true
          next
        elsif line =~ (/\A\/PRE/) then
          retval << '</pre>'
          pre_tag = false
          next
        end

        if pre_tag then
          retval << CGI.escapeHTML(line + "\n")
        elsif line =~ /\A\/?[A-Z~]+\b/        # hnf command is consisted CAPITAL letters and begin at the head of line.
          if line =~ (/\AOK/) then
            next
          elsif line =~ (/\A(TENKI|WEATHER|BASHO|LOCATION|TAIJU|WEIGHT|TAION|TEMPERATURE|SUIMIN|SLEEP|BGM|HOSU|STEP|HON|BOOK|KITAKU|HOMECOMING|WALK|RUN)\s+(.+)/) then
            next
          elsif line =~ (/\ASUB\s+(.+)/) then
            retval << sprintf("<p><b>%s</b>:", $1)
            next
          elsif line =~ (/\ALSUB\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
            retval << sprintf("<p><b><a href=\"%s://%s\">%s</a></b>", $1, $2, $3)
            next
          elsif line =~ (/\ALINK\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
            retval << sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
            next
          elsif line =~ (/\AL?IMG\s+(l|r|n)\s+(\S+)\.(jpg|jpeg|gif|png)/i) then
            line = $2
            if $1 == 'l' then
              retval << sprintf("<img align=\"left\" src=\"%s.%s\" />", $2, $3)
            elsif $1 == 'r' then
              retval << sprintf("<img align=\"right\" src=\"%s.%s\" />", $2, $3)
            else
              retval << sprintf("<img src=\"%s.%s\" />", $2, $3)
            end
          end

          if line =~ (/\A(\/)?(UL|P|OL|DL)/) then
            retval << sprintf("<%s%s>", $1, $2)
            next
          elsif line =~ (/\A(\/)?(CITE)/) then
            unless $1 then
              retval << sprintf("<p><%s>", $2)
            else
              retval << sprintf("<%s%s></p>", $1, $2)
            end
            next
          elsif line =~ (/\ALI\s+(.+)/) then
            retval << sprintf("<li>%s", $1)
            next
          elsif line =~ (/\A\/LI/) then
            retval << '</li>'
            next
          end
        elsif line =~ (/\A~/) then
          retval << '<br />'
        else
          retval << CGI.escapeHTML(line + "\n")
        end
      end

      return retval
    end # def body_to_html

=begin rdoc

=== DonRails::HNF#body_to_xml

=end

    def body_to_xml
      begin
        bth = '<html><body>' + self.body_to_html + '</body></html>'
        if pt == 'hpricot'
          return Hpricot.XML(bth)
        elsif pt == 'htree'
          xml = HTree.parse(bth).to_rexml
          return xml.to_s
        end
      rescue
        p $!
        return self.body_to_html
      end
    end # def body_to_xml

  end # module HNF

end # module DonRails
