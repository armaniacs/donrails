#!/usr/bin/ruby

require 'readline'
require 'pathname'
require 'yaml'

adapter = nil

basedir = Pathname.new($0).dirname.parent.parent


print "setup script for donrails\n\n"
print "base directory path: " + basedir.expand_path + "\n"
print "Where is donrails's top directory? (default:" + basedir.expand_path + ")\n"


buf = Readline.readline("> ", true)
if buf == ""
  buf = basedir
end
topdir = Pathname.new(buf)
unless topdir.directory?
  print "wrong path. exit\n"
  exit 1
end
if topdir.children.include? topdir + "rails"
  print "You have already run \"rails rails\". Go next.\n"
else
  print "You have to run \"rails rails\" or \"make link\" at #{topdir}. \n"
  print "exit\n"
  exit 1
end


cfpath = topdir + "rails/config/database.yml"
unless cfpath.exist?
  print "Use example database.yml\n"
  example_path = topdir + "donrails/config/database.yml"
  exe_yaml = example_path.read
  cf = open(cfpath, "w")
  cf.write(exe_yaml)
  cf.close
end

config_yaml = cfpath.read
config_obj = YAML::load(config_yaml)
pre_obj = YAML::load(config_yaml)
print "Founded database.yml\n"
puts config_yaml
buf = Readline.readline("Do you want to use/keep this? [y/n]", true)
if buf == "y"
  print "Sure. I Use/Keep database.yml\n"
else
  adapter = ''
  config_obj.delete('development')
  config_obj['development'] = Hash.new

  print "\n****** Setup database.yml    *******\n"
  print "\n****** (development section) *******\n"
  print "Select database adapter from mysql/postgresql/sqlite/sqlite3.\n"
  print "Default: " + pre_obj['development']['adapter'] + "\n"
  buf = Readline.readline("> ", true)
  if buf =~ /^(mysql|postgresql|sqlite|sqlite3)$/
    config_obj['development']['adapter'] = buf
  elsif buf == ""
    if pre_obj['development']['adapter']
      config_obj['development']['adapter'] = pre_obj['development']['adapter']
    else
      print "input supported adapter!\n"
      exit
    end
  else
    print "input supported adapter!\n"
    exit
  end


  if config_obj['development']['adapter'] =~ /sqlite3?/
    print "Select database file for sqlite0/3.\n"
    print "Default: " + pre_obj['development']['dbfile'] + "\n" if pre_obj['development']['dbfile']
    buf = Readline.readline("> ", true)
    if buf == ""
      config_obj['development']['dbfile'] = pre_obj['development']['dbfile'] if  pre_obj['development']['dbfile']
    else
      config_obj['development']['dbfile'] = buf
    end

    print "\n\n********* NOTICE *********\n\n"
    print "You have to set #{config_obj['development']['dbfile']} file and directory permission. (Recommends: Chown www-data.www-data)\n"
    print "\n\n********* NOTICE *********\n\n"
    Readline.readline("If you understand, ENTER some key. ", true)

  else

    ["database", "host", "username", "password"].each do |entry|
      print "Input #{entry} name.\n"
      print "Default: " + pre_obj['development']['#{entry}'] + "\n" if pre_obj['development']['#{entry}']
      buf = Readline.readline("> ", true)
      if buf == "" 
        config_obj['development']["#{entry}"] = pre_obj['development']["#{entry}"] if pre_obj['development']['#{entry}']
      else
        config_obj['development']["#{entry}"] = buf
      end
    end
  end

  print "\v Please confirm NEW database.yml\n"
  puts config_obj.to_yaml
  buf = Readline.readline("Is this correct? Can I write on file? [N/y] >", true)
  if buf == "y"
    cfpath = topdir + "rails/config/database.yml"
    exit unless cfpath.writable? 
    cf = open(cfpath, "w")
    cf.write(config_obj.to_yaml)
    cf.close
  else
    print "no write. skip.\n"
  end
end

print "\n****** Setup donrails_env.rb **********\n"
penv = ''
envpath = topdir + "rails/config/environments/donrails_env.rb"
if envpath.exist?
  print "Founded #{envpath}\n"
  puts envpath.read
end

buf = Readline.readline("Do you want to keep? [y/n]", true)
if buf == "y"
  print "Sure. I Keep #{envpath}\n"
else
  buf = Readline.readline("Input username for administration. If you do not input, I will generate for you.. >", true)
  if buf == ""
    d_username = open("/dev/random").read(2).unpack("H*").first
    penv += "ADMIN_USER = \"#{d_username}\"\n"
    print "Generated. you have to use #{d_username}\n"
  else
    penv += "ADMIN_USER = \"#{buf}\"\n"
    d_username = buf
  end
  buf = Readline.readline("Input password for administration. If you do not input, I will generate for you.. >",nil)
  if buf == ""
    d_password = open("/dev/random").read(4).unpack("H*").first
    penv += "ADMIN_PASSWORD = \"#{d_password}\"\n"
    print "Generated. you have to use #{d_password}\n"
  else
    penv += "ADMIN_PASSWORD = \"#{buf}\"\n"
  end

  print "\v Please confirm NEW donrails_env.rb\n"
  puts penv

  buf = Readline.readline("Is this correct? Can I write on file? [N/y] >", true)

  if buf == "y"
    cf = open(envpath, "w")
    cf.write(penv)
    cf.close
  else
    print "no write. skip.\n"
  end

end

envfile = topdir + "rails/config/environment.rb"
envfiledata = open(envfile, "a")
envfiledata.write("\n")
envfiledata.write("require_dependency \"environments/donrails_env\"\n")
envfiledata.write("require_dependency \"antispam\"\n")
envfiledata.write("$KCODE = 'u'\n")
envfiledata.close

