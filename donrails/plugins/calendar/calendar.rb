=begin

=Calendar class 

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'date'
require 'cgi'


module DonRails

=begin rdoc

== DonRails::Calendar

=end

  class Calendar

    class << self

      def thismonth
        d = Date.today

	return DonRails::Calendar.new(d.year, d.month)
      end # def thismonth

    end

=begin rdoc

=== DonRails::Calendar#new(year, month)

=end

    def initialize(year, month)
      @year = year
      @month = month
      @labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S']
      @articles = {}
      @urls = []
    end # def initialize

=begin rdoc

=== DonRails::Calendar#+(num)

=end

    def +(num)
      raise TypeError, sprintf("expected Numeric, but not %s", num.class) unless num.kind_of?(Numeric)

      d = Date.new(@year, @month, 1) >> num

      return DonRails::Calendar.new(d.year, d.month)
    end # def +

=begin rdoc

=== DonRails::Calendar#-(num)

=end

    def -(num)
      raise TypeError, sprintf("expected Numeric, but not %s", num.class) unless num.kind_of?(Numeric)

      d = Date.new(@year, @month, 1) << num

      return DonRails::Calendar.new(d.year, d.month)
    end # def +

=begin rdoc

=== DonRails::Calendar#label=(array)

=end

    def label=(array)
      raise TypeError, sprintf("expected Array, but not %s", array.class) unless array.kind_of?(Array)
      raise ArgumentError, sprintf("wrong number of labels (%s for 7)", array.length) unless array.length != 7

      @labels = array
    end # def label=

=begin rdoc

=== DonRails::Calendar#set_article(article)

=end

    def set_article(article)
      da = article.article_date
      d = Date.new(da.year, da.month, da.days)
      @articles[d] = [] unless @articles.has_key?(d)
      @articles[d].push(article)
    end # def set_article

=begin rdoc

=== DonRails::Calendar#header

=end

    def header
      return sprintf("%s, %s", Date::MONTHNAMES[@month], @year)
    end # def header

=begin rdoc

=== DonRails::Calendar#to_html

=end

    def to_html
      retval = ""

      dstart = Date.new(@year, @month, 1)
      dend = (dstart >> 1) - 1

      # output headers
      retval << "<table class=\"calendar\" summary=\"Calendar\"><thead><tr class=\"calendar-head\">\n"
      0.upto(6) do |n|
        retval << sprintf("<td class=\"calendar-%s\">%s</td>", _class_name(n), @labels[n])
      end
      retval << "\n</tr></thead>\n<tr><td></td></tr><tr>"

      # output empty cells
      0.upto(dstart.wday - 1) do |n|
        retval << sprintf("<td class=\"calendar-%s\"> </td>", _class_name(n).downcase)
      end
      # output days
      (dstart..dend).each do |d|
        # make a day view
        day = d.day
        if @articles.has_key?(d) && !@articles[d].empty? then
          label = ""
          len = @articles[d].length
          n = 0
          while n < len do
            label << sprintf("%d. %s\n", n + 1, @articles[d][n].title_to_html.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, ''))
            n += 1
          end
          day = sprintf("<a class=\"calendar\" title=\"%s\" href=\"FIXME!!\">%s</a>", CGI.escapeHTML(label), d.day)
        end
        retval << sprintf("<td class=\"calendar-%s%s\">%s</td>", _class_name(d.wday), d == Date.today ? '-today' : '', day)
        if d.wday == 6 then
          retval << "</tr>\n"
          retval << "<tr>" if dend != d
        end
      end
      # output empty cells
      (dend.wday + 1).upto(6) do |n|
        retval << sprintf("<td class=\"calendar-%s\"> </td>", _class_name(n))
      end
      retval << "</tr></table>\n"

      return retval
    end # def to_html

    private

    def _class_name(wday)
      retval = "weekday"

      if wday == 0 || wday == 6 then
        retval = Date::DAYNAMES[wday].downcase
      end

      return retval
    end # def _class_name

  end # class Calendar

end # module DonRails

if $0 == __FILE__ then
  c = DonRails::Calendar.new
  p c
end
