=begin

=Plugin library

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'yaml'


module DonRails

=begin rdoc

== DonRails::Plugin

=end

  class Plugin
    class << self

=begin rdoc

=== DonRails::Plugin#stylesheets

=end

      def stylesheets
        retval = []

	pls = ::Plugin.find_by_sql("SELECT * from plugins WHERE activation = true")
        return ['base'] if pls.nil?

        pls.each do |pl|
          begin
            yml = pl.manifest
            list = YAML.load(File.open(yml).read)
            next unless list.has_key?('Stylesheets')
            retval.push(*list['Stylesheets'])
          rescue => e
          end
        end

        retval.push('base')

        return retval
      end # def stylesheets

    end # class << self


  end # class Plugin

end # module DonRails
