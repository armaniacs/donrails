# moinmoin.rb - MoinMoin file format parser
# Copyright (C) 2006 Akira TAGOH

# Authors:
#   Akira TAGOH  <at@gclab.org>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

require 'cgi'
require '../delegator' if $0 == __FILE__

pt = nil
begin
  require 'hpricot'
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

=begin rdoc

==Moinmoin - http://moinmoin.wikiwikiweb.de/HelpOnEditing

==Format:

''blah''	italic
'''blah'''	bold
`blah`		monospace
{{{blah}}}	code
__blah__	underline
^blah^		superscript
,,blah,,	subscript
~-blah-~	smaller
~+blah+~	larger
--(blah)--	stroke
[[BR]]		insert a line break

= blah =	header
== blah ==	header 2
=== blah ===	header 3
==== blah ====	header 4
===== blah =====
		header 5

WikiName	internal link [unsupported]
["Page"] or ["free link"]
		internal free link [unsupported]
http://example.net
		external link [not implemented here. but rely on auto_link outside this module.]
[:HelpContents:Contents of the Help]
		named internal link [unsupported]
[http://example.net example site]
		named external link
attachment:graphics.png
		local graphics (attachment) [unsupported]
http://example.net/image.png
		external graphics

 1. blah	numbered list
 i. blah	roman numbered list
 I. blah	roman numbered list (capital)
 a. blah	alphabet numbered list
 A. blah	alphabet numbered list (capital)
 . blah		unordered list without the list style
 blah		unordered list without the list style
 * blah		unordered list
 blah:: blah	definition list

=end

module DonRails

=begin rdoc

== DonRails::Moinmoin

=end

  module Moinmoin
    include DonRails::PlainText

=begin rdoc

=== DonRails::Moinmoin#title_to_html

=end

    def title_to_html
      MoinMoinParser.init_params()
      line = self.to_s
      line.extend(DonRails::MoinMoinParser)

      return line.convert_inline
    end # def title_to_html

=begin rdoc

=== DonRails::Moinmoin#title_to_xml

=end

    def title_to_xml
      return self.title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def title_to_xml

=begin rdoc

=== DonRails::Moinmoin#body_to_html

=end

    def body_to_html
      paragraphs = []
      retval = ''
      lines = self.to_s.split(/\r\n|\r|\n/)
      colorized_module = nil
      need_paragraph_separated = false
      paragraph_candidate = nil

      MoinMoinParser.init_params()

      (0..lines.length-1).each do |n|
        line = lines[n]
        n += 1
        line.extend(DonRails::MoinMoinParser)

        if line.empty? then
          # postpone determining the paragraph separation.
          need_paragraph_separated = true
          paragraph_candidate = retval if paragraph_candidate.nil?
          retval = ''
          next
        end

        # inline syntax, but not allowed for title
        if line =~ /\[\[BR\]\]/ then
          line.gsub!(/\[\[BR\]\]/, '<br/>')
        end
        if line =~ /\[\[(\w+)\]\]/ then
          # invoking macros
          name = $1
          proc = DonRails::MoinMoinMacro.find(name)
          line.gsub!(/\[\[\w+\]\]/, proc.call) unless proc.nil?
        elsif line =~ /\[\[(\w+)\((.*?)\)\]\]/ then
          # invoking macros with arguments
          name = $1
          args = []
          harg = {}
          $2.split(',').each do |x|
            if x =~ /(\S+)\s*=\s*(.*)/ then
              harg[$1] = $2
            else
              args.push(x)
            end
          end
          unless harg.empty? then
            args.push(harg)
          end
          proc = DonRails::MoinMoinMacro.find(name)
          line.gsub!(/\[\[\w+\]\]/, proc.call(*args)) unless proc.nil?
        end

        if line =~ /\A(=+)\s+(.*)\s+(=+)\Z/ then
          shlen = $1.length
          context = $2
          ehlen = $3.length
          if shlen == ehlen then
            ehlen = shlen = 5 if shlen > 5

            if need_paragraph_separated then
              paragraph_candidate << MoinMoinParser.flush_blocks
              unless paragraph_candidate.empty? then
                paragraphs.push(paragraph_candidate)
              end
              paragraph_candidate = nil
              need_paragraph_separated = false
            end

            retval << sprintf("<h%d>%s</h%d>", shlen, context, ehlen)
            next
          end
        end
        if line =~ /\A(\-+)\Z/ then
          hrlen = $1.length
          if hrlen >= 4 then
            hrlen = 10 if hrlen > 10

            if need_paragraph_separated then
              paragraph_candidate << MoinMoinParser.flush_blocks
              unless paragraph_candidate.empty? then
                paragraphs.push(paragraph_candidate)
              end
              paragraph_candidate = nil
              need_paragraph_separated = false
            end

            retval << sprintf("<hr%s/>", (hrlen > 4 ? sprintf(" class=\"hr%d\"", hrlen - 4) : ''))
            next
          end
        end

        if line =~ /\{\{\{.*?*\}\}\}/ then
          line.gsub!(/(.*)\{\{\{(.*?)\}\}\}(.*)/,
                     sprintf("%s<tt>%s</tt>%s",
                             $1.extend(DonRails::MoinMoinParser).convert_inline,
                             $2,
                             $3.extend(DonRails::MoinMoinParser).convert_inline))
          line.gsub!(/<tt><\/tt>/, '')
        elsif line =~ /\A\{\{\{#!(.*)\Z/ then
          # colorized code
          colorized_module = $1
        else
          line = line.convert_inline
        end

        # precheck for linebreak
        if need_paragraph_separated then
          if line =~ /\A(\s+).*/ then
            retval = sprintf("%s%s", paragraph_candidate, retval)
          else
            paragraph_candidate << MoinMoinParser.flush_blocks
            unless paragraph_candidate.empty? then
              paragraphs.push(paragraph_candidate)
            end
          end
          paragraph_candidate = nil
          need_paragraph_separated = false
        end

        retval << line.convert_block
      end
      retval << MoinMoinParser.flush_blocks

      unless retval.empty? then
        paragraphs.push(retval)
      end

      return "<p>" + paragraphs.join('</p><p>') + "</p>"
    end # def body_to_html

=begin rdoc

=== DonRails::Moinmoin#body_to_xml

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

=begin rdoc

==== DonRails::Moinmoin::BlockTagBase

=end

    class NotImplementedYet < StandardError; end

    class BlockTagBase

      def to_tag
	raise NotImplementedYet
      end # def to_tag

      def to_sym
	raise NotImplementedYet
      end # def to_sym

    end # class BlockTagBase

=begin rdoc

==== DonRails::Moinmoin::List

=end

    class List < BlockTagBase

      def initialize(list_type)
	@list_type = list_type
      end # def initialize

      def to_sym
	return @list_type.to_sym
      end # def to_sym

      def to_tag
        retval = ''

        case @list_type
        when :nlist, :nlist_with_i, :nlist_with_I, :nlist_with_a, :nlist_with_A
          retval = 'ol'
        when :ulist, :ulist_no_style, :ulist_no_style_or_append_line
          retval = 'ul'
        when :dlist
          retval = 'dl'
        else
        end

        return retval
      end # def to_tag

      def params
	retval = ''

        case @list_type
        when :nlist
          retval = ' type="1"'
        when :ulist, :ulist_no_style, :ulist_no_style_or_append_line
        when :nlist_with_i, :nlist_with_I, :nlist_with_a, :nlist_with_A
          retval = sprintf(" type=\"%s\"", @list_type.to_s.sub(/\Anlist_with_/, ''))
        when :dlist
        else
        end

        return retval
      end # def params

      def item_params
	retval = ''

        case @list_type
        when :nlist, :nlist_with_i, :nlist_with_I, :nlist_with_a, :nlist_with_A
        when :ulist
        when :ulist_no_style, :ulist_no_style_or_append_line
          retval = ' style="list-style-type:none"'
        when :dlist
        else
        end

        return retval
      end # def params

    end # class List

  end # module Moinmoin

  module MoinMoinParser

    @@is_bold = false
    @@is_italic = false
    @@is_pre = false
    @@indent_level = 0
    @@tag_stack = []
    @@content_stack_level = -1
    @@table_stack = []

    BlockStruct = Struct.new(:tag, :indent_level, :is_child_closed)

    class << self

      def init_params
	@@is_bold = false
        @@is_italic = false
        @@is_pre = false
        @@indent_level = 0
        @@tag_stack = []
        @@content_stack_level = -1
        @@table_stack = []
      end # def init_params

      def flush_table
        retval = ''
        ncolumn = 0
        @@table_stack.each do |x|
          ncolumn = x.length if x.length > ncolumn
        end

        # XXX: tags not yet implemented
        # XXX: table generated doesn't look like moinmoin. need rework to get better.
        retval << "<table>"
        @@table_stack.each do |x|
          retval << "<tr>"
          0.upto(ncolumn-1) do |n|
            retval << sprintf("<td>%s</td>", x[n]) unless x[n].nil?
          end
          retval << "</tr>"
        end
        retval << "</table>"
        @@table_stack.clear

        return retval
      end # def flush_table

      def flush_block(info)
        retval = ''

        retval << '</li>' unless info.is_child_closed
        retval << sprintf("</%s>", info.tag.to_tag)

        return retval
      end # def flush_block

      def flush_blocks
        retval = ''

        retval << DonRails::MoinMoinParser.flush_table unless @@table_stack.empty?

        @@tag_stack.reverse.each do |info|
          retval << flush_block(info)
        end
        @@tag_stack.clear

        return retval
      end # def flush_blocks

    end

    def convert_inline
      target = self.to_s
      supported_image_format = '\.(?:jpg|jpeg|png|gif|tiff)'
      supported_protocol_format = '(?:\w+:\/\/)'

      return target if @@is_pre

      if target =~ /'''''.*?''.*'''/ then
        # <strong><em>blah</em>...</strong>
        target.gsub!(/'''(''.*?''.*)'''/, '<strong>\1</strong>')
      elsif target =~ /'''''.*?'''.*''/ then
	# <em><strong>blah</em>...</strong>
        target.gsub!(/((?:''))'''(.*?)'''(.*(?:''))/, '\1<strong>\2</strong>\3')
      elsif target =~ /'''.*?(?:(?:'').*(?:''))'''/ then
	target.gsub!(/'''(.*?(?:(?:'').*(?:'')))'''/, '<strong>\1</strong>')
      elsif target =~ /'''.*?'''/ then
        target.gsub!(/'''(.*?)'''/, '<strong>\1</strong>')
        target.gsub!(/<strong><\/strong>/, '')
      end
      if target =~ /''.*?''/ then
        target.gsub!(/''(.*?)''/, '<em>\1</em>')
        target.gsub!(/<em><\/em>/, '')
      end
      if target =~ /'''/ then
        target.sub!(/'''/, (@@is_bold ? '</strong>' : '<strong>'))
        @@is_bold = !@@is_bold
      end
      if target =~ /''/ then
	target.sub!(/''/, (@@is_italic ? '</em>' : '<em>'))
        @@is_italic = !@@is_italic
      end
      if target =~ /__.*?__/ then
        target.gsub!(/__(.*?)__/, '<u>\1</u>')
        target.gsub!(/<u><\/u>/, '')
      end
      if target =~ /\^[^^]*\^/ then
        target.gsub!(/\^([^^]*)\^/, '<sup>\1</sup>')
        target.gsub!(/<sup><\/sup>/, '')
      end
      if target =~ /,,.*?,,/ then
        target.gsub!(/,,(.*?),,/, '<sub>\1</sub>')
        target.gsub!(/<sub><\/sub>/, '')
      end
      if target =~ /~\-.*?\-~/ then
        target.gsub!(/~\-(.*?)\-~/, '<small>\1</small>')
        target.gsub!(/<small><\/small>/, '')
      end
      if target =~ /~\+.*?\+~/ then
        target.gsub!(/~\+(.*?)\+~/, '<big>\1</big>')
        target.gsub!(/<big><\/big>/, '')
      end
      if target =~ /\-\-\(.*?\)\-\-/ then
        target.gsub!(/\-\-\((.*?)\)\-\-/, '<stroke>\1</stroke>')
        target.gsub!(/<stroke><\/stroke>/, '')
      end
      if target =~ /\[#{supported_protocol_format}[^\[\s]*\s+[^\[]*\]/ then
        target.gsub!(/\[(#{supported_protocol_format}[^\[\s]*)\s+([^\[]*)\]/, '<a href="\1">\2</a>')
      end
      if target =~ /\[#{supported_protocol_format}[^\[\s]*#{supported_image_format}\]/ then
        target.gsub!(/\[(#{supported_protocol_format}[^\[\s]*)\]/, '<a href="\1"><img alt="\1" src="\1" title="\1"/></a>')
      end
      if target =~ /\[#{supported_protocol_format}[^\[\s]*\]/ then
        target.gsub!(/\[(#{supported_protocol_format}[^\[\s]*)\]/, '<a href="\1">\1</a>')
      end
      if target =~ /(?:\A|\s+)(#{supported_protocol_format}\S+#{supported_image_format})(?:\Z|\s+)/ then
	url = $1
        filename = File.basename(url).gsub(/\.\S+\Z/, '')
        target.gsub!(/(#{supported_protocol_format}\S+#{supported_image_format})/,
                     sprintf("<img alt=\"%s\" src=\"%s\" title=\"%s\"/>",
                             filename, url, filename))
      end
      if target =~ /(?:\A|\s+)(#{supported_protocol_format}\S+)(?:\Z|\s+)/ then
	url = $1
	target.gsub!(/(#{supported_protocol_format}\S+)/,
	sprintf("<a href=\"%s\">%s</a>", url, url))
      end

      return convert_smileys
    end # def convert_inline

    def convert_smileys
      target = self.to_s
      smileys = {
        '\(!\)' => 'idea.png',
        '\(\./\)' => 'checkmark.png',
        "\/!\\\\" => 'alert.png',
        ':\(' => 'sad.png',
        ':\)' => 'smile.png',
        ':\)\)' => 'smile3.png',
        ':\-\(' => 'sad.png',
        ':\-\)' => 'smile.png',
        ':\-\)\)' => 'smile3.png',
        ':\-\?' => 'tongue.png',
        ':D' => 'biggrin.png',
        ':\\\\' => 'ohwell.png',
        ':o' => 'redface.png',
        ';\)' => 'smile4.png',
        ';\-\)' => 'smile4.png',
        '<!>' => 'attention.png',
        '<:\(' => 'frown.png',
        '>:>' => 'devil.png',
        'B\)' => 'smile2.png',
        'B\-\)' => 'smile2.png',
        'X\-\(' => 'angry.png',
        '\{\*\}' => 'star_on.png',
        '\{1\}' => 'prio1.png',
        '\{2\}' => 'prio2.png',
        '\{3\}' => 'prio3.png',
        '\{OK\}' => 'thumbs-up.png',
        '\{X\}' => 'icon-error.png',
        '\{i\}' => 'icon-info.png',
        '\{o\}' => 'star_off.png',
        '\|\)' => 'tired.png',
        '\|\-\)' => 'tired.png',
      }

      smileys.each do |k, v|
        if target =~ /#{k}/ then
# XXX: need some configuration stuff to determine where icons are installed on.
#          target.gsub!(/#{k}/,
#                       sprintf("<img alt=\"%s\" height=\"15\" src=\"%s\" title=\"%s\" width=\"15\"/>",
#                               k, v, k))
        end
      end

      return target
    end # def convert_smileys

    def convert_block
      retval = ''
      target = self.to_s
      was_pre = @@is_pre
      list_type = nil
      indent_level = 0
      content = nil
      nstart = nil
      is_table = false

      if target =~ /\{\{\{\Z/ && !@@is_pre then
	@@is_pre = true
        target.sub!(/\{\{\{\Z/, '<pre>')
      end
      if target =~ /\}\}\}\Z/ && @@is_pre then
        @@is_pre = false
        was_pre = false
        target.sub!(/\}\}\}\Z/, '</pre>')
      end

      return target + "\n" if @@is_pre && was_pre

      if target =~ /\A(\s+)\d+\.((?:#\d+)?)\s+(.*)/ then
        indent_level = $1.length
        nstart = $2
        content = $3
        nstart = nil if nstart.empty?
        list_type = :nlist
      elsif target =~ /\A(\s+)\*\s+(.*)/ then
	indent_level = $1.length
        content = $2
        list_type = :ulist
      elsif target =~ /\A(\s+)(i|I|a|A)\.((?:#\d+)?)\s+(.*)/ then
	indent_level = $1.length
        style = $2
        nstart = $3
        content = $4
        nstart = nil if nstart.empty?
        list_type = sprintf("nlist_with_%s", style).to_sym
      elsif target =~ /\A(\s+)\.\s+(.*)/ then
	indent_level = $1.length
        content = $2
        list_type = :ulist_no_style
      elsif target =~ /\A(\s+)(.*)::\s+(.*)\Z/ then
	indent_level = $1.length
        content = sprintf("<dt>%s</dt><dd>%s</dd>", $2, $3)
        list_type = :dlist
      elsif target =~ /\A(\s+)(.*)/ then
	indent_level = $1.length
        content = $2
        list_type = :ulist_no_style_or_append_line
      elsif target =~ /\A\|\|(.*)\|\|\Z/ then
	@@table_stack.push($1.split('||'))
        is_table = true
      else
        retval << target
      end

      if !@@table_stack.empty? && !is_table then
        retval << DonRails::MoinMoinParser.flush_table
      end

      unless list_type.nil? then
	retval << convert_block_list(list_type, indent_level, nstart, content)
      end

      return retval
    end # def convert_block

    private

    def convert_block_list(list_type, indent_level, nstart, content)
      retval = ''

      if indent_level > @@indent_level then
        @@content_stack_level += 1
        tag = DonRails::Moinmoin::List.new(list_type)
        @@tag_stack.push(BlockStruct.new(tag, indent_level, false))
        @@indent_level = indent_level
        if list_type == :dlist then
          retval << sprintf("<%s>%s", tag.to_tag, content)
          @@tag_stack[@@content_stack_level].is_child_closed = true
        else
          retval << sprintf("<%s%s%s><li%s>%s", tag.to_tag,
                            (nstart.nil? ? "" : sprintf(" start=\"%d\"", nstart.sub(/\A#/, '').to_i)),
                            tag.params, tag.item_params, content)
        end
      elsif indent_level == @@indent_level then
	if list_type == :ulist_no_style_or_append_line then
          retval << sprintf(" %s", content)
        elsif list_type == :dlist then
          if @@tag_stack[@@content_stack_level].tag.to_sym != :dlist &&
              !@@tag_stack[@@content_stack_level].is_child_closed then
            retval << '</li>'
            @@tag_stack[@@content_stack_level].is_child_closed = true
          end
          retval << content
        else
          retval << '</li>' unless @@tag_stack[@@content_stack_level].is_child_closed
          retval << sprintf("<li%s>%s", @@tag_stack[@@content_stack_level].tag.item_params, content)
        end
      else
        info = @@tag_stack.pop
        @@content_stack_level -= 1
        if @@tag_stack.empty? then
          @@indent_level = 0
        else
          @@indent_level = @@tag_stack[@@tag_stack.length-1].indent_level
        end
        retval = MoinMoinParser.flush_block(info)
        retval << convert_block_list(list_type, indent_level, nstart, content)
      end

      return retval
    end # def convert_block_list

  end # module MoinMoinParser

  module MoinMoinMacro

    class << self

      def find(name)
        # XXX: implement me

	return nil
      end # def find

    end

  end # module MoinMoinMacro

end # module DonRails


if $0 == __FILE__ then
  require 'runit/testcase'
  require 'runit/cui/testrunner'

  class TestDonRails__Moinmoin < RUNIT::TestCase

    def __getobj__(str)
      str.extend(DonRails::Moinmoin)

      return str
    end # def __getobj__

    def setup
    end # def setup

    def teardown
    end # def teardown

    def test_body_to_html
      assert_equal('<p><em>Italic</em></p>', __getobj__("''Italic''\n").body_to_html)
      assert_equal('<p><em>foo</em>bar<em>baz</em></p>', __getobj__("''foo''bar''\nbaz''\n").body_to_html)

      assert_equal('<p><strong>Bold</strong></p>', __getobj__("'''Bold'''\n").body_to_html)
      assert_equal('<p><strong>Bold:</strong></p>', __getobj__("'''Bold:'''\n").body_to_html)
      assert_equal("<p><strong>'bold</strong></p>", __getobj__("''''bold'''\n").body_to_html)
      assert_equal('<p><em><strong>Mix</strong> at the beginning</em></p>', __getobj__("'''''Mix''' at the beginning''\n").body_to_html)
      assert_equal('<p><strong><em>Mix</em> at the beginning</strong></p>', __getobj__("'''''Mix'' at the beginning'''\n").body_to_html)
      assert_equal('<p><strong>Mix at the <em>end</em></strong></p>', __getobj__("'''Mix at the ''end'''''\n").body_to_html)
      assert_equal('<p><em>Mix at the <strong>end</strong></em></p>', __getobj__("''Mix at the '''end'''''\n").body_to_html)
      assert_equal('<p><em>foo<strong>bar</em>baz</strong>hoge</p>', __getobj__("''foo'''bar''baz'''hoge\n").body_to_html)

      assert_equal('<p><u>underline</u></p>', __getobj__("__underline__").body_to_html)
      assert_equal('<p><u><strong>underline</strong></u></p>', __getobj__("__'''underline'''__\n").body_to_html)

      assert_equal('<p><sup>super</sup>script</p>', __getobj__("^super^script\n").body_to_html)
      assert_equal('<p><sub>sub</sub>script</p>', __getobj__(",,sub,,script\n").body_to_html)
      assert_equal('<p><small>small</small></p>', __getobj__("~-small-~\n").body_to_html)
      assert_equal('<p><big>big</big></p>', __getobj__("~+big+~\n").body_to_html)
      assert_equal('<p><stroke>stroke</stroke></p>', __getobj__("--(stroke)--\n").body_to_html)
      assert_equal('<p><em>a</em><sup>2</sup> + <em>b</em><sup>2</sup> = <em>c</em><sup>2</sup></p>', __getobj__("''a''^2^ + ''b''^2^ = ''c''^2^\n").body_to_html)
      assert_equal('<p><h1>foo</h1></p>', __getobj__("= foo =\n").body_to_html)
      assert_equal('<p><h2>foo</h2></p>', __getobj__("== foo ==\n").body_to_html)
      assert_equal('<p><h3>foo</h3></p>', __getobj__("=== foo ===\n").body_to_html)
      assert_equal('<p><h4>foo</h4></p>', __getobj__("==== foo ====\n").body_to_html)
      assert_equal('<p><h5>foo</h5></p>', __getobj__("===== foo =====\n").body_to_html)
      assert_equal('<p><h5>foo</h5></p>', __getobj__("====== foo ======\n").body_to_html)
      assert_equal('<p>===== foo ====</p>', __getobj__("===== foo ====\n").body_to_html)
      assert_equal('<p><hr/></p>', __getobj__("----\n").body_to_html)
      assert_equal('<p><hr class="hr1"/></p>', __getobj__("-----\n").body_to_html)
      assert_equal('<p><hr class="hr2"/></p>', __getobj__("------\n").body_to_html)
      assert_equal('<p><hr class="hr3"/></p>', __getobj__("-------\n").body_to_html)
      assert_equal('<p><hr class="hr4"/></p>', __getobj__("--------\n").body_to_html)
      assert_equal('<p><hr class="hr5"/></p>', __getobj__("---------\n").body_to_html)
      assert_equal('<p><hr class="hr6"/></p>', __getobj__("----------\n").body_to_html)
      assert_equal('<p><hr class="hr6"/></p>', __getobj__("--------------------\n").body_to_html)
      assert_equal('<p>---</p>', __getobj__("---\n").body_to_html)
      assert_equal('<p><a href="http://example.net">example site</a></p>', __getobj__("[http://example.net example site]\n").body_to_html)
      assert_equal('<p><a href="http://example.net">http://example.net</a></p>', __getobj__("[http://example.net]\n").body_to_html)
      assert_equal('<p><img alt="donrails" src="http://example.net/donrails.png" title="donrails"/></p>', __getobj__("http://example.net/donrails.png\n").body_to_html)
      assert_equal('<p><a href="http://example.net/donrails.png"><img alt="http://example.net/donrails.png" src="http://example.net/donrails.png" title="http://example.net/donrails.png"/></a></p>', __getobj__("[http://example.net/donrails.png]\n").body_to_html)
      assert_equal('<p><a href="http://example.net/donrails.png">donrails.png</a></p>', __getobj__("[http://example.net/donrails.png donrails.png]\n").body_to_html)
      assert_equal('<p><br/></p>', __getobj__("[[BR]]\n").body_to_html)
      assert_equal('<p>foo</p><p>bar</p>', __getobj__("foo\n\nbar\n").body_to_html)
      assert_equal('<p>foo</p><p>bar</p>', __getobj__("foo\n\n\nbar\n").body_to_html)

      assert_equal("<p><pre>foo\nbar\n</pre></p>", __getobj__("{{{\nfoo\nbar\n}}}\n").body_to_html)

      assert_equal('<p><ol type="1"><li>foo</li><li>bar</li></ol></p>', __getobj__(" 1. foo\n 1. bar\n").body_to_html)
      assert_equal('<p><ol type="1"><li>foo<ol type="1"><li>bar</li></ol></li></ol></p>', __getobj__(" 1. foo\n  1. bar\n").body_to_html)
      assert_equal('<p><ol type="1"><li>foo<ol type="1"><li>bar</li></ol></li><li>baz</li></ol></p>', __getobj__(" 1. foo\n  1. bar\n 1. baz\n").body_to_html)
      assert_equal("<p><ol type=\"1\"><li>foo</li><li><pre>foo\nbar\n</pre></li></ol></p>", __getobj__(" 1. foo\n 1. {{{\nfoo\nbar\n}}}\n").body_to_html)
      assert_equal('<p><ul><li style="list-style-type:none">foo</li><li style="list-style-type:none">bar</li></ul></p>', __getobj__(" . foo\n . bar\n").body_to_html)
      assert_equal('<p><ul><li>foo</li><li>bar</li></ul></p>', __getobj__(" * foo\n * bar\n").body_to_html)
      assert_equal('<p><ul><li>foo</li><li>bar</li><li>baz<ul><li>fooo<ul><li>foooo</li></ul></li></ul></li><li>hoge</li></ul></p>', __getobj__(" * foo\n * bar\n * baz\n  * fooo\n   * foooo\n * hoge\n").body_to_html)
      assert_equal('<p><ul><li>foo bar</li></ul></p>', __getobj__(" * foo\n bar\n").body_to_html)
      assert_equal('<p><ul><li>foo bar</li></ul></p>', __getobj__("  * foo\n  bar\n").body_to_html)
      assert_equal('<p><ul><li>foo bar<ul><li style="list-style-type:none">baz</li></ul></li></ul></p>', __getobj__("  * foo\n  bar\n    baz\n").body_to_html)
      assert_equal('<p><ol type="i"><li>foo</li><li>bar</li></ol></p>', __getobj__(" i. foo\n i. bar\n").body_to_html)
      assert_equal('<p><ol type="I"><li>foo</li><li>bar</li></ol></p>', __getobj__(" I. foo\n I. bar\n").body_to_html)
      assert_equal('<p><ol type="a"><li>foo</li><li>bar</li></ol></p>', __getobj__(" a. foo\n a. bar\n").body_to_html)
      assert_equal('<p><ol type="A"><li>foo</li><li>bar</li></ol></p>', __getobj__(" A. foo\n A. bar\n").body_to_html)
      assert_equal('<p><ol start="42" type="I"><li>foo</li><li>bar</li></ol></p>', __getobj__(" I.#42 foo\n I. bar\n").body_to_html)
      assert_equal('<p><ol start="42" type="I"><li>foo</li><li>bar</li></ol></p>', __getobj__(" I.#42 foo\n I.#44 bar\n").body_to_html)
      assert_equal('<p><ul><li>foo</li></ul></p><p>bar</p>', __getobj__(" * foo\n\nbar\n").body_to_html)
      assert_equal('<p><dl><dt>term</dt><dd>definition</dd></dl></p>', __getobj__(" term:: definition\n").body_to_html)
      assert_equal('<p><dl><dt>term</dt><dd>definition</dd><dt>another term</dt><dd>and its definition</dd></dl></p>', __getobj__(" term:: definition\n another term:: and its definition\n").body_to_html)
      assert_equal('<p>foo<ul><li>list 1</li><li>list 2<ol type="1"><li>number 1</li><li>number 2</li></ol></li><dt>term</dt><dd>definition</dd></ul></p><p><a href="https://mope.example.net/mope/">https://mope.example.net/mope/</a></p>', __getobj__("foo\n * list 1\n * list 2\n  1. number 1\n  1. number 2\n\n term:: definition\n\nhttps://mope.example.net/mope/\n").body_to_html)
      assert_equal('<p>foo<ul><li>list 1</li><li>list 2<ol type="1"><li>number 1</li><li>number 2</li><dt>term</dt><dd>definition</dd></ol></li></ul></p><p><a href="https://mope.example.net/mope/">https://mope.example.net/mope/</a></p>', __getobj__("foo\n * list 1\n * list 2\n  1. number 1\n  1. number 2\n\n  term:: definition\n\nhttps://mope.example.net/mope/\n").body_to_html)
      assert_equal('<p>foo<ul><li>list 1</li><li>list 2<ol type="1"><li>number 1</li><li>number 2<dl><dt>term</dt><dd>definition</dd></dl></li></ol></li></ul></p><p><a href="https://mope.example.net/mope/">https://mope.example.net/mope/</a></p>', __getobj__("foo\n * list 1\n * list 2\n  1. number 1\n  1. number 2\n\n   term:: definition\n\nhttps://mope.example.net/mope/\n").body_to_html)
      assert_equal('<p>foo<ul><li>list 1</li><li>list 2<ol type="1"><li>number 1</li><li>number 2</li></ol></li></ul><dl><dt>term</dt><dd>definition</dd></dl></p><p><a href="https://mope.example.net/mope/">https://mope.example.net/mope/</a></p>', __getobj__("foo\n  * list 1\n  * list 2\n   1. number 1\n   1. number 2\n\n term:: definition\n\nhttps://mope.example.net/mope/\n").body_to_html)
#      assert_equal('<p><table><tr><td>foo</td><td>bar</td></tr></table></p>', __getobj__("||foo||bar||\n").body_to_html)
      assert_equal('<p></p>', __getobj__("\n").body_to_html)
    end # def test_body_to_html

  end # class TestDonRails__Moinmoin

  suite = RUNIT::TestSuite.new
  ObjectSpace.each_object(Class) do |klass|
    if klass.ancestors.include?(RUNIT::TestCase) then
      suite.add_test(klass.suite)
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
