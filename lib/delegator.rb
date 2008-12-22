=begin

=Data Format Delegator

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end


module DonRails

=begin rdoc

== DonRails::DataFormatDelegator

=end

  class DataFormatDelegator
    class << self

=begin rdoc

=== DonRails::DataFormatDelegator#formatmap

=end

      def formatmap
        retval = {}

        unless defined?($formatmap) then
          pp = File.join(File.dirname(__FILE__), 'modules', '*rb')
          Dir.glob(pp).each do |fn|
            begin
              Kernel.load(fn)
              fmt = File.basename(fn).sub(/.rb\Z/, '').downcase
              modlist = []
              modlist.push(sprintf("DonRails::%s", fmt.upcase))
              modlist.push(sprintf("DonRails::%s", fmt.capitalize))

              catch(:map) do
                modlist.each do |m|
                  ObjectSpace.each_object(Module)  do |k|
                    if k.ancestors.map{|n| n.to_s}.include?(m) then
                      retval[fmt] = m
                      throw(:map)
                    end
                  end
                end
              end # catch
            rescue => e
            end
          end # Dir.glob

          retval['plain'] = 'DonRails::PlainText'
          $formatmap = retval
	end

        return $formatmap
      end # def formatmap

=begin rdoc

=== DonRails::DataFormatDelegator#formatlist

=end

      def formatlist
        m = DataFormatDelegator.formatmap

        return m.keys
      end # def formatlist

    end

=begin rdoc

=== DonRails::DataFormatDelegator#new(obj, type)

=end

    def initialize(obj, type)
      raise TypeError, sprintf("can't convert %s into String", fmt.class) unless type.kind_of?(String)

      @__obj__ = obj
      @__module__ = nil
      @__type__ = type

      begin
        if DataFormatDelegator.formatlist.include?(obj.format) then
          @__module__ = eval(DataFormatDelegator.formatmap[obj.format])
        else
          @__module__ = eval(DataFormatDelegator.formatmap['plain'])
        end
      rescue
        @__module__ = eval(DataFormatDelegator.formatmap['plain'])
      end
    end # def initialize

    undef :id

    def method_missing(m, *args)
      if m.to_s =~ /\A(\w+)_to_#{@__type__.downcase}\Z/ then
        text = @__obj__.__send__($1)
        text.extend(@__module__)
        if text.respond_to?(m) then
          text.__send__(m, *args)
        else
          raise NoMethodError, sprintf("undefined method `%s' for %s", m, self)
        end
      else
        @__obj__.__send__(m, *args)
      end
    end # def method_missing

  end # class DataFormatDelegator

=begin rdoc

== DonRails::PlainText

=end

  module PlainText

=begin rdoc

=== DonRails::PlainText#title_to_html

=== DonRails::PlainText#title_to_xml
=end

    def title_to_html
      return self.to_s
    end # def title_to_html

    alias :title_to_xml :title_to_html

=begin rdoc

=== DonRails::PlainText#body_to_html

=end

    def body_to_html
      return self.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '').gsub("\n", "<br>\n")
    end # def body_to_html

=begin rdoc

=== DonRails::PlainText#body_to_xml

=end

    def body_to_xml
      return self.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def body_to_xml

  end # module PlainText

end # module DonRails
