=begin

=RD file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'rd/rdfmt'
require 'rd/rd2html-lib'


module DonRails

=begin rdoc

== DonRails::RD

=end

  module RD
    include DonRails::PlainText

    def self.extend_object(obj)
      super

      obj.instance_variable_set(:@_rd_visitor, nil)
      if $Visitor_Class then
        obj.instance_variable_set(:@_rd_visitor, $Visitor_Class.new)
      end
    end # def extend_object

=begin rdoc

=== DonRails::RD#title_to_html

=end

    def title_to_html
      src = sprintf("=begin\n%s\n=end\n", self.to_s.sub(/\A=+\s+(.*)/, '\1').chomp)
      tree = ::RD::RDTree.new(src)
      retval = @_rd_visitor.visit(tree)

      return retval.gsub(/.*<body>(.*)<\/body>.*/m, '\1').gsub(/.*<p>(.*)<\/p>.*/m, '\1').sub(/\A\n/,'').chomp
    end # def title_to_html

=begin rdoc

=== DonRails::RD#title_to_xml

=end

    def title_to_xml
      return self.title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def title_to_xml

=begin rdoc

=== DonRails::RD#body_to_html

=end

    def body_to_html
      src = sprintf("=begin\n%s\n=end\n", self.to_s.chomp)
      tree = ::RD::RDTree.new(src)
      retval = @_rd_visitor.visit(tree)

      return retval.gsub(/.*<body>(.*)/m, '\1').gsub(/(.*)<\/body>.*/m, '\1').sub(/\A\n/,'').chomp
    end # def body_to_html

=begin rdoc

=== DonRails::RD#body_to_xml

=end

    def body_to_xml
      begin
        bth = '<html><body>' + self.body_to_html + '</body></html>'
        xml = HTree.parse(bth).to_rexml
        return xml.to_s
      rescue
        p $!
        return self.body_to_html
      end
    end # def body_to_xml

  end # module RD

end # module DonRails
