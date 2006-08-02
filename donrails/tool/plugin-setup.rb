#! /usr/bin/env ruby

=begin

=Plugin setup utility for donrails

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'rbconfig'
require 'optparse'
require 'yaml'


class Conf < Hash

  def confdir
    return self.has_key?('confdir') ? self['confdir'] : './'
  end # def confdir

  def confdir=(dir)
    self['confdir'] = dir
  end # def confdir=

  def quiet?
    return self.has_key?('quiet') ? self['quiet'] : false
  end # def quiet?

  def quiet=(flag)
    self['quiet'] = (flag == true ? true : false)
  end # def quiet=

  def use_symlink?
    return self.has_key?('use_symlink') ? self['use_symlink'] : true
  end # def use_symlink?

  def use_symlink=(flag)
    self['use_symlink'] = (flag == true ? true : false)
  end # def use_symlink=

  def dryrun?
    return self.has_key?('dryrun') ? self['dryrun'] : false
  end # def dryrun?

  def dryrun=(flag)
    self['dryrun'] = (flag == true ? true : false)
  end # def dryrun=

  def dbi
    return ActiveRecord::Base.retrieve_connection
  end # def dbi

  def force?
    return self.has_key?('force') ? self['force'] : false
  end # def force?

  def force=(flag)
    self['force'] = (flag == true ? true : false)
  end # def force=

end # class Conf

class Installer

  INSTALL = 0
  UNINSTALL = 1

  def initialize(conf, mode)
    @conf = conf
    @mode = mode
    @path = nil
  end # def initialize

  def message(itype, name, to)
    printf("%s %s %s%s%s%s\n", type2string(itype), @mode, name, (itype == INSTALL ? ' to ' : '... '), to, (itype == INSTALL ? (@conf.use_symlink? ? '(Symlink)' : '(Copy)') : '')) unless @conf.quiet?
  end # def message

  def install(list, path)
    raise TypeError, sprintf("%ss has to be Array, but not %s", @mode, list.class) unless list.kind_of?(Array)
    list.each do |n|
      p = File.join(@path, File.basename(n))
      message(INSTALL, n, @path)
      unless FileTest.exist?(@path) then
	printf("Creating a directory `%s'...\n", @path) unless @conf.quiet?
        FileUtils.mkdir_p(@path) unless @conf.dryrun?
      end
      if @conf.use_symlink? then
	FileUtils.ln_sf(File.expand_path(File.join(path, n)), p) unless @conf.dryrun?
      else
        FileUtils.install(File.join(path, n), p) unless @conf.dryrun?
      end
    end
  end # def install

  def uninstall(list)
    raise TypeError, sprintf("%ss has to be Array, but not %s", @mode, list.class) unless list.kind_of?(Array)
    list.each do |n|
      message(UNINSTALL, n, '')
      f = File.join(@path, n)
      if FileTest.exist?(f) then
	File.unlink(f) unless @conf.dryrun?
      else
        printf("  %s %s does not exist!\n", @mode, f)
      end
    end
  end # def uninstall

  private

  def type2string(itype)
    retval = "unknown"

    case itype
    when INSTALL
      retval = "Installing"
    when UNINSTALL
      retval = "Uninstalling"
    end

    return retval
  end # def type2string

end # class Installer

class ModuleInstaller < Installer

  def initialize(conf)
    super(conf, 'Module')
    @path = File.join(RAILS_ROOT, '..', 'donrails', 'lib', 'plugins')
  end # def initialize

end # class ModuleInstaller

class TemplateInstaller < Installer

  def initialize(conf)
    super(conf, 'Template')
    @path = File.join(RAILS_ROOT, '..', 'donrails', 'app', 'views', 'plugins')
  end # def initialize

end # class TemplateInstaller

class StylesheetInstaller < Installer

  def initialize(conf)
    super(conf, 'Stylesheet')
    @path = File.join(RAILS_ROOT, 'public', 'stylesheets')
  end # def initialize

end # class StylesheetInstaller

class TableInstaller < Installer

  def initialize(conf, dbi)
    @dbi = dbi
    super(conf, 'Table')
  end # def initialize

end # class TableInstaller


if $0 == __FILE__ then
  begin
    Version = "0.1"
    conf = Conf.new
    maps = {
      'Modules'=>false,
      'Templates'=>false,
      'Stylesheets'=>false,
      'Tables'=>true,
    }

    command = ARGV.shift
    case command
    when 'install'
      ARGV.options do |opt|
        opt.banner = sprintf("Usage: %s %s [options] <plugin directory>", __FILE__, command)
        opt.on('--configdir=DIR', 'Specify the configuration directory for RoR') {|v| conf.confdir = v}
        opt.on('--[no-]quiet', 'no output during installation') {|v| conf.quiet = v}
        opt.on('--no-symlink', 'Copy files instead of using symlinks') {|v| conf.use_symlink = v}
        opt.on('--dry-run', 'Do not do anything actually') {|v| conf.dryrun = v}
	opt.on('--force', 'Install a plugin forcibly') {|v| conf.force = v}
        opt.parse!
      end
      if ARGV.empty? then
        printf("Please type %s %s --help for more details.\n", __FILE__, command)
        exit 1
      end
      $:.unshift(conf.confdir)
      require 'environment'

      dir = File.expand_path(ARGV.shift)

      begin
        list = YAML.load(File.open(File.join(dir, 'MANIFEST.yml')).read)
      rescue => e
        p e
        exit 1
      end

      if list.empty? then
        print "No valid items found.\n"
        exit 1
      end
      unless list.has_key?('Name') then
        print "No Name item found.\n"
        exit 1
      end
      unless list.has_key?('Description') then
        print "No Description item found.\n"
        exit 1
      end

      name = list['Name']
      desc = list['Description']
      list.delete('Name')
      list.delete('Description')

      pl = Plugin.find(:first, :conditions => ['name = ?', name])
      if !pl.nil? && !conf.force? then
        printf("Plugin `%s' has already been installed.\n", name)
        exit 1
      end

      dbi = conf.dbi

      maps.each do |k, v|
        if list.has_key?(k) then
          i = eval(sprintf("%sInstaller.new(conf%s)", k.sub(/s\Z/, ''), (v == true ? ', dbi' : '')))
          i.install(list[k], dir)
          list.delete(k)
        end
      end
      unless list.empty? then
        print "WARNING: unknown data is specified\n"
        list.each do |k, v|
          printf("\t%s: %s\n", k, v.inspect)
        end
      end
      p = Plugin.new('name' => name,
                     'description' => desc,
                     'manifest' => File.join(dir, 'MANIFEST.yml'),
                     'activation' => true)
      p.save
    when 'remove'
      ARGV.options do |opt|
        opt.banner = sprintf("Usage: %s %s [options] <name>", __FILE__, command)
        opt.on('--configdir=DIR', 'Specify the configuration directory for RoR') {|v| conf.confdir = v}
        opt.on('--dry-run', 'Do not do anything actually') {|v| conf.dryrun = v}
        opt.parse!
      end
      if ARGV.empty? then
        printf("Please type %s %s --help for more details.\n", __FILE__, command)
        exit 1
      end
      $:.unshift(conf.confdir)
      require 'environment'

      pl = Plugin.find(:first, :conditions => ['name = ?', ARGV[0]])
      if pl.nil? then
        printf("Plugin `%s' has never been installed.\n", ARGV[0])
        exit 1
      end
      yml = pl.manifest

      begin
        list = YAML.load(File.open(yml).read)
      rescue => e
        p e
        exit 1
      end

      if list.empty? then
        print "No valid items found.\n"
        exit 1
      end

      list.delete('Name')
      list.delete('Description')
      dbi = conf.dbi

      maps.each do |k, v|
        if list.has_key?(k) then
          i = eval(sprintf("%sInstaller.new(conf%s)", k.sub(/s\Z/, ''), (v == true ? ', dbi' : '')))
          i.uninstall(list[k])
          list.delete(k)
        end
      end
      unless list.empty? then
        print "WARNING: unknown data is specified\n"
        list.each do |k, v|
          printf("\t%s: %s\n", k, v.inspect)
        end
      end
      pl.destroy unless conf.dryrun?
    when '--help'
      print <<__EOH__
Usage: #{__FILE__} <Sub Command> [<Options>] ...
Sub Commands:
  install
  remove
__EOH__
      printf("\nPlease type %s <Sub Command> --help to see the help of the options for Sub Command.\n", __FILE__)
      exit 1
    else
      printf("Please type %s --help for more details.\n", __FILE__)
      exit 1
    end
  ensure
    if ActiveRecord::Base.connected? then
      ActiveRecord::Base.remove_connection
    end
  end
end
