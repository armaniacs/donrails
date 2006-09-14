#! /usr/bin/env ruby
# td2db.rb
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

require 'optparse'
require 'kconv'
require 'erb'


class TD2DBConfig < Hash

  def tdiarydir=(val)
    self['tdiarydir'] = val
  end # def tdiarydir=

  def tdiarydir
    return self.has_key?('tdiarydir') ? self['tdiarydir'] : '/usr/share/tdiary'
  end # def tdiarydir

  def confdir=(val)
    self['confdir'] = val
  end # def confdir=

  def confdir
    return self.has_key?('confdir') ? self['confdir'] : './'
  end # def confdir

  def dryrun=(val)
    self['dryrun'] = (val ? true : false)
  end # def dryrun

  def dryrun
    return self.has_key?('dryrun') ? self['dryrun'] : false
  end # def dryrun

  def tdiaryconfdir=(val)
    self['tdiaryconfdir'] = val
  end # def tdiaryconfdir=

  def tdiaryconfdir
    return self.has_key?('tdiaryconfdir') ? self['tdiaryconfdir'] : './'
  end # def tdiaryconfdir

end # class TD2DBConfig


if $0 == __FILE__ then
  conf = TD2DBConfig.new
  ARGV.options do |opt|
    opt.banner = sprintf("Usage: %s [options] <directory>", __FILE__)
    opt.on('--tdiarydir=DIR', 'DIR where tDiary modules are installed') {|v| conf.tdiarydir = v}
    opt.on('--confdir=DIR', 'DIR where the configuration directory for ROR') {|v| conf.confdir = v}
    opt.on('--dry-run', 'Actually not do anything') {|v| conf.dryrun = true}
    opt.on('--tdiaryconfdir=DIR', 'DIR where tdiary.conf is put on') {|v| conf.tdiaryconfdir = v}
    opt.parse!
  end
  if $DEBUG then
    conf.dryrun = true
  end

  if ARGV.empty? then
    print("Please see more details with --help.\n");
    exit 1
  end
  $:.unshift(conf.tdiarydir)
  $:.unshift(conf.confdir)

  require 'environment'
  require 'antispam'
  require 'active_record'
  require 'logger'
  require 'article'
  require 'enrollment'
  require 'category'
  require 'comment'

  require 'tdiary'
  require 'tdiary/tdiary_style'
  require 'tdiary/defaultio'

  eval <<-EOE
  def File.open(name, mod = 'r', *args, &block)
    begin
      super(File.join("#{conf.tdiaryconfdir}", name), mod, *args, &block)
    rescue Errno::ENOENT
      super(name, mod, *args, &block)
    end
  end # def File.open
  EOE

  module TDiary

    class Dummy

      def initialize(conf = nil)
	@conf = conf
      end # def initialize

      def method_missing(m, *args)
        @methods = [:restore_parser_cache, :store_parser_cache]

        if @methods.include?(m) then
          return nil
        elsif m == :conf then
          return @conf unless @conf.nil?
        elsif m == :[] then
          if args[0] == 'conf' then
            return @conf unless @conf.nil?
          end
        end
#        printf("%s - %s\n", m.inspect, args.inspect)

	return self
      end # def method_missing

    end # class Dummy 

    class TD2DB_DefaultIO < TDiary::DefaultIO

      attr_reader :dfile

      def initialize(dir, conf)
	@dummy = Dummy.new(conf)
        super(@dummy)
        @data_path = dir
      end # def initialize

      def restore_referer(file, diaries)
	
      end # def restore_referer

    end # class TD2DB_DefaultIO

  end # module TDiary

  tdconf = TDiary::Config.new

  ARGV.each do |dir|
    d = File.join(dir, '') if dir !~ /\/\Z/
    files = Dir.glob(File.join(d, '*/*.td2'))
    io = TDiary::TD2DB_DefaultIO.new(d, tdconf)
    files.each do |f|
      next unless File.basename(f) =~ /^(\d{4})(\d{2})/
      date = Time.local($1, $2)
      io.transaction(date) do |diaries|
        diaries.keys.sort.each do |key|
          printf("%s\n", key)
          diary = diaries[key]
          comments = []
          diary.each_comment do |com|
            comments.push(com)
          end
          plugin = TDiary::Plugin.new('conf'=>tdconf,
                                      'mode'=>"",
                                      'diaries'=>diaries,
                                      'cgi'=>TDiary::Dummy.new(tdconf),
                                      'years'=>date.year,
                                      'cache_path'=>(tdconf.cache_path || File.join(tdconf.data_path, "cache")),
                                      'date'=>date,
                                      'comment'=>comments,
                                      'last_modified'=>diary.last_modified)

          def plugin._eval_rhtml(rhtml)
            r = ERB.new(rhtml.untaint).result(binding)
            r = ERB.new(r).src

            return r
          end # def plugin._eval_rhtml
          def plugin._body_enter_proc(date)
            r = body_enter_proc(date)

            return r.nil? ? "" : Kconv.toutf8(r)
          end # def _body_enter_proc
          def plugin._body_leave_proc(date)
            r = body_leave_proc(date)

            return r.nil? ? "" : Kconv.toutf8(r)
          end # def _body_leave_proc

          i = 1
          a = nil
          if conf.dryrun then
            printf("\n\n%s's diary\n", diary.date.strftime("%Y-%m-%d"))
            print "LastModified: #{diary.last_modified}\n"
            print "Visibility: #{diary.visible?}\n"
          end
          diary.each_section do |sec|
            stitle = Kconv.toutf8(sec.stripped_subtitle)
            hd = plugin._body_enter_proc(Time.at(diary.date.to_i))
            r = Kconv.toutf8(plugin.eval_src(plugin._eval_rhtml(sec.body_to_html).untaint, false))
            ft = plugin._body_leave_proc(Time.at(diary.date.to_i))
            sbody = sprintf("%s%s%s", hd, r, ft)
            if conf.dryrun then
              print "\nArticle #{i}:\n"
              print "Title: #{stitle}\n"
              print "body: #{sbody}\n"
              print "Categories: #{sec.categories.join(' ')}\n"
            else
              a = Article.new('title'=>stitle,
                              'body'=>sbody,
                              'article_date'=>diary.date.strftime("%Y-%m-%d"),
                              'article_mtime'=>diary.last_modified,
                              'size'=>sbody.length,
                              'hidden'=>(diary.visible? ? 0 : 1),
                              'format'=>'html')
              e = Enrollment.new('title'=>stitle,
                                 'hidden'=>(diary.visible? ? 0 : 1),
                                 'created_at'=>diary.last_modified,
                                 'updated_at'=>diary.last_modified)
              e.save
              a.enrollment_id = e.id
              sec.categories.each do |cat|
                ucat = Kconv.toutf8(cat)
                q = Category.find(:first, :conditions => ['name = ?', ucat])
                if q then
                  a.categories.push_with_attributes(q)
                else
                  c = Category.new('name'=>ucat)
                  c.save
                  a.categories.push_with_attributes(c)
                end
              end
              a.save
            end
            i += 1
          end
          i = 1
          diary.each_comment do |com|
            cbody = Kconv.toutf8(com.body)
            cname = Kconv.toutf8(com.name)
            if conf.dryrun then
              print "Comment #{i}:\n"
              print "Posted: #{com.date}\n"
              print "Visibility: #{com.visible?}\n"
              print "Name: #{cname}\n"
              print "email: #{com.mail}\n"
              print "body: #{cbody}\n"
            else
              cm = Comment.new('password'=>(com.mail.nil? || com.mail.empty? ? cname : com.mail),
                               'article_id'=>a.id,
                               'date'=>com.date,
                               'title'=>a.title,
                               'author'=>cname,
                               'hidden'=>(com.visible? ? 0 : 1),
                               'body'=>cbody)
              cm.save
            end
            i += 1
          end
        end
        TDiary::TDiaryBase::DIRTY_NONE
      end
    end
  end
end
