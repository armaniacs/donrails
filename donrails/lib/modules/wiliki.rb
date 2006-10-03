=begin

=Wiliki file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'cgi'
require '../delegator' if $0 == __FILE__

=begin rdoc

==WiLiKi - http://www.shiro.dreamhost.com/scheme/wiliki/wiliki.cgi

==Format:

  ;;		comment - no output in html - only the beginning of line
  ~		continuous line - only the beginning of line
  ----		horizontal rule - <hr> - only the beginning of line
  [empty line]	the end of paragraph - </p>
  ~%		line feed - <br>
  ''blah''	emphasis - <em> - inline
  '''blah'''	strong emphasis - <strong> - inline
  [[blah]]	link - need to support this? - inline
  [link blah]	link
  space		formatted text - <pre> - only the beginning of line
  {{{
  blah
  }}}		formatted text - but as is
  <<<
  blah
  >>>		quoted text - <blockquote>
  *		header - <h?> - only the beginning of line
  -		list - <ul> - only the beginning of line
  #		list - <ol> - only the beginning of line
  :desc:blah	data description - <dd> <dt> - only the beginning of line
  ||blah||	table - <table>
  $$img url [desc]	inline image

=end

module DonRails

=begin rdoc

== DonRails::Wiliki

=end

  module Wiliki
    include DonRails::PlainText

=begin rdoc

=== DonRails::Wiliki#title_to_html

=end

    def title_to_html
      line = self.to_s

      if line =~ (/'''.*?'''/) then
        line.gsub!(/'''(.*?)'''/, '<strong>\1</strong>')
        line.gsub!(/<strong><\/strong>/, '')
      elsif line =~ (/\A[^']*'''[^']*\Z/) then
        # nothing to do help in this case
      end
      if line =~ (/''.*?''/) then
        line.gsub!(/''(.*?)''/, '<em>\1</em>')
        line.gsub!(/<em><\/em>/, '')
      elsif line =~ (/\A[^']*''[^']*\Z/) then
        # nothing to do help in this case
      end
      if line =~ (/\[\[/) then
        if line =~ (/\[\[.*?\]\]/) then
          # do we really need to support this? how?
          # FIXME: just drop it ATM.
          line.gsub!(/\[\[(.*?)\]\]/, '\1')
        else
          # try to look at next line.
          if lines[n] =~ (/\A~/) then
            lprev = line
            next
          end
        end
      elsif line =~ (/\[/) then
        if line =~ (/\[[^\[]*\]/) then
          line.gsub!(/\[((?:(?:http|https|ftp):\/\/)[^\[\s]*)\s+([^\]]*)\]/, '<a href="\1">\2</a>')
        else
          # nothing to do help in this case
        end
      end

      return line
    end # def title_to_html

=begin rdoc

=== DonRails::Wiliki#title_to_xml

=end

    def title_to_xml
      return self.title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def title_to_xml

=begin rdoc

=== DonRails::Wiliki#body_to_html

=end

    def body_to_html
      retval = ""
      buf = []
      lprev = nil
      block_stack = []
      list_stack = []
      table_stack = []
      stop = false
      header = nil
      onelinepre = false

      lines = self.to_s.split(/\r\n|\r|\n/)
      len = lines.length
      n = 0
      while n < len do
        line = lines[n]
        n += 1

        if line =~ (/\A\{\{\{\Z/) then
          # the beginning of formatted text
          unless header.nil? then
            retval << output_header(lprev, header)
            lprev = nil
          end
          unless list_stack.empty? then
            list_stack.push(nil)
            retval << _output_list(buf, list_stack, list_stack.length, list_stack[-1])
            list_stack.pop
          end
          retval << output_table(table_stack) unless table_stack.empty?
          retval << output_block(buf, block_stack)

          block_stack.push('pre')
          stop = true
          next
        elsif line =~ (/\A\}\}\}\Z/) then
          # the end of formatted text
          if block_stack[-1] == 'pre' then
            retval << output_block(buf, block_stack)
          else
            buf.push(line)
          end
          stop = false
          next
        end

        if stop then
          buf.push(CGI.escapeHTML(line))
        else
          if line =~ (/\A~/) then
            # continuous line.
            line.sub!(/\A~/, '')
            unless lprev.nil? then
              line = sprintf("%s%s", lprev, line)
              lprev = nil
              if header =~ (/\Ah([0-9]+)\Z/) then
                line = sprintf("%s %s", '*' * ($1.to_i - 1), line)
              end
            end
          else
            unless header.nil? then
              retval << output_header(lprev, header)
              lprev = nil
            end
          end
          if line !~ (/\A<<<\Z/) && line !~ (/\A>>>\Z/) then
            line = CGI.escapeHTML(line)
          end
          line.gsub!(/~%/, "<br />")

          # inline
          if line =~ (/((?:''''')).*?\1/) then
            line.gsub!(/((?:'''''))(.*?)\1/, '<em><strong>\2</strong></em>')
            line.gsub!(/<strong><\/strong>/, '')
          end
          if line =~ (/((?:''')).*?\1/) then
            line.gsub!(/((?:'''))(.*?)\1/, '<strong>\2</strong>')
            line.gsub!(/<strong><\/strong>/, '')
          elsif line =~ (/\A[^']*'''[^']*\Z/) then
            # try to look at next line.
            if lines[n] =~ (/\A~/) then
              lprev = line
              next
            end
	  end
          if line =~ (/''.*?''/) then
            line.gsub!(/''(.*?)''/, '<em>\1</em>')
            line.gsub!(/<em><\/em>/, '')
          elsif line =~ (/\A[^']*''[^']*\Z/) then
            # try to look at next line.
            if lines[n] =~ (/\A~/) then
              lprev = line
              next
            end
	  end
          if line =~ (/\[\[\$\$img\s+(\S+)(?:\s+(.*))?\]\]/) then
            line.gsub!(/\[\[\$\$img\s+(\S+)(?:\s+(.*))?\]\]/, '<img src="\1" alt="\2" />')
          end
          if line =~ (/\[\[/) then
            if line =~ (/\[\[.*?\]\]/) then
              # do we really need to support this? how?
              # FIXME: just drop it ATM.
              line.gsub!(/\[\[(.*?)\]\]/, '\1')
            else
              # try to look at next line.
              if lines[n] =~ (/\A~/) then
                lprev = line
                next
              end
            end
          elsif line =~ (/\[/) then
            if line =~ (/\[[^\[]*\]/) then
              line.gsub!(/\[((?:(?:http|https|ftp):\/\/)[^\[\s]*)\s+([^\]]*)\]/, '<a href="\1">\2</a>')
            else
              # try to look at next line.
              if lines[n] =~ (/\A~/) then
                lprev = line
                next
              end
            end
          end

          # block
          if line =~ (/\A<<<\Z/) then
            unless list_stack.empty? then
              list_stack.push(nil)
              retval << _output_list(buf, list_stack, list_stack.length, list_stack[-1])
              list_stack.pop
            end
            retval << output_table(table_stack) unless table_stack.empty?
            retval << _output_list(buf, list_stack, 0, nil) unless list_stack.empty?
            retval << output_header(lprev, header) unless header.nil?
            unless block_stack[-2] == 'blockquote' then
              retval << output_block(buf, block_stack)
            else
              tmp = output_block(buf, block_stack)
              tmp.sub!(/\A<blockquote><p>(.*)\Z/, '\1')
              tmp << '<blockquote><p>'
              buf.push(tmp)
            end
            block_stack.push('blockquote')
            block_stack.push('p')
            next
          elsif line =~ (/\A>>>\Z/) then
            if block_stack[-2] == 'blockquote' then
              tmp = output_block(buf, block_stack)
              block_stack.pop
              block_stack.pop
              tmp << '</blockquote>'
              tmp.sub!(/([^(?:<\/p>)]+)(<\/blockquote>)/, '\1</p>\2')
              if block_stack[-2] == 'blockquote' then
                tmp.sub!(/\A<blockquote><p>/, '')
                buf.push(tmp)
                buf.push('<p>')
              else
                retval << tmp
              end
            else
              buf.push(line)
            end
            next
          elsif line =~ (/\A\s+/) then
            if block_stack[-2] == 'blockquote' && block_stack[-1] == 'p' && buf.empty? then
              block_stack[-1] = 'pre'
            elsif block_stack[-1] != 'pre' then
              unless list_stack.empty? then
                list_stack.push(nil)
                retval << _output_list(buf, list_stack, list_stack.length, list_stack[-1])
                list_stack.pop
              end
              retval << output_table(table_stack) unless table_stack.empty?
              retval << output_block(buf, block_stack)
              block_stack.push('pre') if list_stack.empty?
            end
            if lines[n] =~ (/\A~/) then
              lprev = line
            else
              buf.push(line)
            end
            onelinepre = true
            next
          else
            if onelinepre then
              retval << output_block(buf, block_stack)
            end
          end
          if line =~ (/\A(\*+)\s+(.*)\Z/) then
            hn = $1.length + 1
            l = $2
            list_stack.push(nil) unless list_stack.empty?
            retval << _output_list(buf, list_stack, list_stack.length, list_stack[-1]) unless list_stack.empty?
            list_stack.pop
            retval << output_table(table_stack) unless table_stack.empty?
            retval << _output_list(buf, list_stack, 0, nil) unless list_stack.empty?
            retval << output_block(buf, block_stack)
            lprev = l
            header = sprintf("h%d", hn > 6 ? 6 : hn)
            next
          elsif line =~ (/\A(\-+)\s+(.*)\Z/) then
            ln = $1.length
            item = $2
            buf.push(output_table(table_stack)) unless table_stack.empty?
            buf.push(output_list(list_stack, ln, 'ul'))
            buf.push(item)
            next
          elsif line =~ (/\A(#+)\s+(.*)\Z/) then
            ln = $1.length
            item = $2
            buf.push(output_table(table_stack)) unless table_stack.empty?
            buf.push(output_list(list_stack, ln, 'ol'))
            buf.push(item)
            next
          elsif line =~ (/\A:([^:]*):(.*)\Z/) then
            buf.push(output_table(table_stack)) unless table_stack.empty?
            block_stack.push(nil)
            buf.push(sprintf("<dl><dt>%s</dt><dd><p>%s</p></dd></dl>", $1, $2))
            next
          elsif line =~ (/\A\|\|(.*)\|\|/) then
            table_stack.push($1.split('||'))
            next
          elsif line =~ (/\A----\Z/) then
            buf.push(output_table(table_stack)) unless table_stack.empty?
            if block_stack.empty? then
              retval << "<hr>"
            else
              buf.push("<hr>")
            end
            next
          elsif line =~ (/\A;;/) then
            # comment. don't output this to html. just ignore.
            next
          elsif line.empty? then
            retval << output_table(table_stack) unless table_stack.empty?
            retval << _output_list(buf, list_stack, 0, nil) unless list_stack.empty?
            retval << output_block(buf, block_stack)
            next
          else
            if lines[n] =~ (/\A~/) then
              lprev = line
            else
              buf.push(line)
            end
          end
        end # if stop
      end # while n < len

      list_stack.push(nil) unless list_stack.empty?
      retval << _output_list(buf, list_stack, list_stack.length, list_stack[-1]) unless list_stack.empty?
      list_stack.pop
      retval << output_table(table_stack) unless table_stack.empty?
      retval << _output_list(buf, list_stack, 0, nil) unless list_stack.empty?
      retval << output_header(lprev, header) unless header.nil?
      retval << output_block(buf, block_stack)
      if block_stack[-1] == 'p' && block_stack[-2] == 'blockquote' then
        block_stack.pop
      end

      block_stack.each do |x|
        retval << sprintf("</%s>", x) unless x.nil?
      end

      return retval
    end # def body_to_html

=begin rdoc

=== DonRails::Wiliki#body_to_xml

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

    private

    def output_block(buf, block)
      retval = ""

      return "" if buf.empty?

      if block[-2] == 'blockquote' &&
          (block[-1] == 'p' || block[-1] == 'pre') then
        retval << sprintf("<%s><%s>", block[-2], block[-1])
      elsif block.empty? then
        retval << "<p>"
      elsif block[-1].nil? then
	# nothing to do
      else
        retval << sprintf("<%s>", block[-1])
      end
      if block[-1] == 'pre' then
        retval << buf.reject {|x| x.empty?}.join("\n")
        retval << "\n"
      else
        retval << buf.join
      end
      if block[-2] == 'blockquote' && block[-1] == 'p' then
        retval << sprintf("</%s>", block[-1])
        buf.clear

        return retval
      elsif block.empty? then
        retval << "</p>"
      elsif block[-1].nil? then
	# nothing to do
      else
        retval << sprintf("</%s>", block[-1])
      end
      block.pop
      buf.clear

      return retval
    end # def output_block

    def _output_list(buf, list, listlevel, listtype)
      retval = ""

      retval << buf.reject {|x| x.empty?}.join
      buf.clear
      retval << output_list(list, listlevel, listtype)

      return retval
    end # def _output_list

    def output_list(list, listlevel, listtype)
      retval = ""
      flag = false

      if list.length > listlevel then
        1.upto(list.length - listlevel) do |n|
          retval << '</li>'
          retval << sprintf("</%s>", list[-1])
          list.pop
        end
      elsif list.length < listlevel then
	1.upto(listlevel - list.length) do |n|
          retval << sprintf("<%s>", listtype)
          retval << sprintf("<li%s>", (listlevel - list.length) > 1 ? ' class="hidden"' : '')
          list.push(listtype)
          flag = true
        end
      end
      if list[-1] != listtype then
        retval << sprintf("<%s>", listtype)
        retval << '<li>'
        list.pop
        list.push(listtype)
      elsif !listtype.nil? && !flag then
	retval << '</li><li>'
      end

      return retval
    end # def output_list

    def output_table(table)
      retval = ""
      ncolumn = 0
      table.each do |x|
        if x.length > ncolumn then
          ncolumn = x.length
        end
      end

      retval << "<table>"
      table.each do |x|
        retval << "<tr>"
        0.upto(ncolumn-1) do |n|
          retval << sprintf("<td>%s</td>", x[n]) unless x[n].nil?
        end
        retval << "</tr>"
      end
      retval << "</table>"
      table.clear

      return retval
    end # def output_table

    def output_header(line, header)
      retval = ""
      retval << sprintf("<%s>%s</%s>", header, line, header)
      header = nil

      return retval
    end # def output_header

  end # module Wiliki

end # module DonRails


if $0 == __FILE__ then
  require 'runit/testcase'
  require 'runit/cui/testrunner'

  class TestDonRails__Wiliki < RUNIT::TestCase

    def __getobj__(str)
      str.extend(DonRails::Wiliki)

      return str
    end # def __getobj__

    def setup
    end # def setup

    def teardown
    end # def teardown

    def test_body_to_html
      assert_equal('', __getobj__(";; comment\n").body_to_html)
      assert_equal("<p>testtest</p>", __getobj__("test\n~test\n").body_to_html)
      assert_equal("<hr>", __getobj__("----\n").body_to_html)
      assert_equal("<p>test</p>", __getobj__("test\n\n").body_to_html)
      assert_equal("<p>test</p><p>test2</p>", __getobj__("test\n\ntest2\n").body_to_html)
      assert_equal("<p>test<br />test</p>", __getobj__("test~%\ntest\n").body_to_html)
      assert_equal("<p>test<br /></p>", __getobj__("test~\n~%\n").body_to_html)
      assert_equal("<p><em>test</em></p>", __getobj__("''test''\n").body_to_html)
      assert_equal("<p>test~%</p>", __getobj__("test~''''%\n").body_to_html)
      assert_equal("<p><em>test</em></p>", __getobj__("''\n~test\n~''\n").body_to_html)
      assert_equal("<p><em>test</em>'</p>", __getobj__("''test'''\n").body_to_html)
      assert_equal("<p>''test''</p>", __getobj__("''\n~test\n''\n").body_to_html)
      assert_equal("<p><strong>test</strong></p>", __getobj__("'''test'''\n").body_to_html)
      assert_equal("<p><strong>test</strong>'</p>", __getobj__("'''test''''\n").body_to_html)
      assert_equal("<p>test~%</p>", __getobj__("test~''''''%\n").body_to_html)
      assert_equal("<p><strong>test</strong></p>", __getobj__("'''\n~test\n~'''\n").body_to_html)
      assert_equal("<p>'''test'''</p>", __getobj__("'''\n~test\n'''\n").body_to_html)
      # FIXME?
      assert_equal("<p>test</p>", __getobj__("[[test]]\n").body_to_html)
      assert_equal("<p><a href=\"http://www.example.com/\">test</a></p>", __getobj__("[http://www.example.com/ test]\n").body_to_html)
      assert_equal("<p>[test test]</p>", __getobj__("[test test]\n").body_to_html)
      assert_equal("<p><a href=\"https://www.example.com/\">test</a></p>", __getobj__("[https://www.example.com/ test]\n").body_to_html)
      assert_equal("<p><a href=\"ftp://www.example.com/\">test</a></p>", __getobj__("[ftp://www.example.com/ test]\n").body_to_html)
      assert_equal("<p><a href=\"ftp://www.example.com/\">test test</a></p>", __getobj__("[ftp://www.example.com/ test test]\n").body_to_html)
      assert_equal("<pre> test\n</pre>", __getobj__(" test\n").body_to_html)
      assert_equal("<pre> test\n test2\n</pre>", __getobj__(" test\n test2\n").body_to_html)
      assert_equal("<p>test</p><pre> test\n</pre>", __getobj__("test\n test\n").body_to_html)
      assert_equal("<p>test</p><pre> testtest\n</pre>", __getobj__("test\n test\n~test\n").body_to_html)
      assert_equal("<pre>test\n</pre>", __getobj__("{{{\ntest\n}}}\n").body_to_html)
      assert_equal("<pre>test\n test\n</pre>", __getobj__("{{{\ntest\n test\n").body_to_html)
      assert_equal("<p>{{{testtest}}}</p>", __getobj__("{{{test\ntest\n}}}\n").body_to_html)
      assert_equal("<pre>[[test]]\n</pre>", __getobj__("{{{\n[[test]]\n}}}\n").body_to_html)
      assert_equal("<p>test</p><pre> test\n</pre><pre>test\n</pre>", __getobj__("test\n test\n{{{\ntest\n}}}\n").body_to_html)
      assert_equal("<pre>;; test\n</pre>", __getobj__("{{{\n;; test\n}}}\n").body_to_html)
      assert_equal("<h2>test</h2>", __getobj__("* test\n").body_to_html)
      assert_equal("<p>test</p><h2>test</h2>", __getobj__("test\n* test\n").body_to_html)
      assert_equal("<h2>testtest</h2>", __getobj__("* test\n~test\n").body_to_html)
      assert_equal("<h2><strong>test</strong></h2>", __getobj__("* '''test\n~'''\n").body_to_html)
      assert_equal("<h2>* test</h2>", __getobj__("* * test\n").body_to_html)
      assert_equal("<h3>test</h3>", __getobj__("** test\n").body_to_html)
      assert_equal("<ul><li>test</li><li>test</li></ul>", __getobj__("- test\n- test\n").body_to_html)
      assert_equal("<ul><li>test<ul><li>test</li></ul></li><li>test</li></ul>", __getobj__("- test\n-- test\n- test\n").body_to_html)
      assert_equal("<ul><li class=\"hidden\"><ul><li class=\"hidden\"><ul><li>test</li></ul></li><li>test</li></ul></li><li>test</li></ul>", __getobj__("--- test\n-- test\n- test\n").body_to_html)
      assert_equal("<ul><li>test<pre>test\n</pre></li><li>test</li></ul>", __getobj__("- test\n{{{\ntest\n}}}\n- test\n").body_to_html)
      assert_equal("<ol><li>test</li><li>test</li></ol>", __getobj__("# test\n# test\n").body_to_html)
      assert_equal("<ol><li>test<ol><li>test</li></ol></li><li>test</li></ol>", __getobj__("# test\n## test\n# test\n").body_to_html)
      assert_equal("<dl><dt>test</dt><dd><p>test2</p></dd></dl>", __getobj__(":test:test2\n").body_to_html)
      assert_equal("<ul><li>test<dl><dt>test</dt><dd><p>test</p></dd></dl></li><li>test</li></ul>", __getobj__("- test\n:test:test\n- test\n").body_to_html)
      assert_equal("<table><tr><td>test</td></tr></table>", __getobj__("||test||\n").body_to_html)
      assert_equal("<ul><li>test<table><tr><td>test</td></tr></table></li></ul>", __getobj__("- test\n||test||\n").body_to_html)
      assert_equal("<ul><li>test</li></ul><h2>test</h2>", __getobj__("- test\n* test\n").body_to_html)
      assert_equal("<ul><li>test<table><tr><td>test</td></tr></table><pre>test\n</pre></li></ul>", __getobj__("- test\n||test||\n{{{\ntest\n}}}\n").body_to_html)
      assert_equal("<ul><li>test<table><tr><td>test</td></tr></table> test</li></ul>", __getobj__("- test\n||test||\n test\n").body_to_html)
      assert_equal("<table><tr><td>test</td><td>test2</td></tr><tr><td>test</td><td>test2</td></tr></table>", __getobj__("||test||test2||\n||test||test2||\n").body_to_html)
      assert_equal("<table><tr><td>test|</td></tr></table>", __getobj__("||test|||\n").body_to_html)
      assert_equal("<table><tr><td>test</td></tr><tr><td>test</td><td>test2</td></tr></table>", __getobj__("||test||\n||test||test2||n").body_to_html)
      assert_equal("<blockquote><p>test</p></blockquote>", __getobj__("<<<\ntest\n>>>\n").body_to_html)
      assert_equal("<blockquote><p>test</p><blockquote><p>test</p></blockquote><p>test</p></blockquote>", __getobj__("<<<\ntest\n<<<\ntest\n>>>\ntest\n>>>\n").body_to_html)
      assert_equal("<blockquote><p>test</p><pre> test\n</pre><pre>test\n</pre></blockquote>", __getobj__("<<<\ntest\n test\n{{{\ntest\n}}}\n>>>\n").body_to_html)
      assert_equal("<blockquote><p>test</p></blockquote>", __getobj__("<<<\ntest\n").body_to_html)
      assert_equal("<blockquote><pre> - foobar\n   barbaz\n</pre></blockquote>", __getobj__("<<<\n - foobar\n   barbaz\n>>>\n").body_to_html)
      assert_equal("<p>test</p><pre>;; test\n</pre>", __getobj__("test\r\n\r\n{{{\r\n;; test\r\n}}}\r\n").body_to_html)
      assert_equal("<p>test</p><pre>;; test\n</pre>", __getobj__("test\r\r{{{\r;; test\r}}}\r").body_to_html)
      assert_equal("<pre>&lt;&lt;&lt;\n</pre>", __getobj__("{{{\n<<<\n}}}\n").body_to_html)
      assert_equal("<pre> &gt;\n</pre>", __getobj__(" >\n").body_to_html)
      assert_equal("<pre> <em>test</em>\n</pre>", __getobj__(" ''test''\n").body_to_html)
      assert_equal("<pre> test\n</pre><p>test</p>", __getobj__(" test\ntest\n").body_to_html)
      assert_equal("<p><em>test</em>abc<em>test</em></p>", __getobj__("''test''abc''test''\n").body_to_html)
      assert_equal("<p><em>test</em>abc<strong>test</strong></p>", __getobj__("''test''abc'''test'''\n").body_to_html)
      assert_equal("<p><em><strong>test</strong></em></p>", __getobj__("'''''test'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em><strong>test</strong></em></p>", __getobj__("'''test''' '''''test'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <em><strong>test</strong></em></p>", __getobj__("'''test''' ''test'' '''''test'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <strong>test</strong> <em><strong>test</strong></em></p>", __getobj__("'''test''' ''test'' '''test''' '''''test'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <em>test</em> <strong>test</strong> <em><strong>test</strong></em></p>", __getobj__("'''test''' ''test'' ''test'' '''test''' '''''test'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <em>test</em> <strong>test</strong> <em><strong>test foo</strong></em></p>", __getobj__("'''test''' ''test'' ''test'' '''test''' '''''test foo'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <em>test</em> <strong>test bar</strong> <em><strong>test foo</strong></em></p>", __getobj__("'''test''' ''test'' ''test'' '''test bar''' '''''test foo'''''\n").body_to_html)
      assert_equal("<p><strong>test</strong> <em>test</em> <em>test</em> <strong>test bar</strong> <em><strong>test foo</strong></em> ...</p>", __getobj__("'''test''' ''test'' ''test'' '''test bar''' '''''test foo''''' ...\n").body_to_html)
      assert_equal("<p><strong>test:</strong> <em>test</em> <em>test</em> <strong>test bar</strong> <em><strong>test foo</strong></em> ...</p>", __getobj__("'''test:''' ''test'' ''test'' '''test bar''' '''''test foo''''' ...\n").body_to_html)
    end # def test_body_to_html

  end # class TestDonRails__Wiliki

  suite = RUNIT::TestSuite.new
  ObjectSpace.each_object(Class)  do |klass|
    if klass.ancestors.include?(RUNIT::TestCase) then
      suite.add_test(klass.suite)
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
