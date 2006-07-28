#!/usr/bin/env ruby

require 'yaml'
require 'getoptlong'
require 'atomcheck'

def usage
  print "#{$0}\n\n"
  print "--username or -a=username:\n\t Set username for WSSE auth.\n"
  print "--password or -p=password:\n\t Set password for WSSE auth.\n"
  print "--target_url=target_url:\n\t Set URL for Atom POST.\n"
  print "--title or -t=title:\n\t Set TITLE for your post article.\n"
  print "--config or -c=configfile:\n\t Set YAML format config file.\n"
  print "--html\n\t Set article format to HTML.\n" 
  print "--hnf\n\t Set article format to HNF.\n"
  print "--nocheck\n\t NO CHECK article is already has posted or not. (Default checkd.)\n"
  print "--preescape\n\t html escape in <pre></pre> text. (Default no preescaped.)\n\t(Some text caused internal server error without this option.)\n"
  print "--content-mode=(escaped)\n\t <content></content> encode mode. (Default no encoded.)\n\t\t'escaped' is the only supported encode mode."
  print "--help\n\t Show this message\n"
  exit
end

user = nil
pass = nil
target_url = nil
title = nil
body = nil
configfile = nil
format = nil
check = true
preescape = false
content_mode = nil

parser = GetoptLong.new
parser.set_options(['--username', '-a', GetoptLong::REQUIRED_ARGUMENT],
                   ['--password', '-p', GetoptLong::REQUIRED_ARGUMENT],
                   ['--target_url', GetoptLong::REQUIRED_ARGUMENT],
                   ['--title', '-t', GetoptLong::REQUIRED_ARGUMENT],
                   ['--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
                   ['--html', GetoptLong::NO_ARGUMENT],
                   ['--hnf', GetoptLong::NO_ARGUMENT],
                   ['--body', '-b', GetoptLong::REQUIRED_ARGUMENT],
                   ['--nocheck', '--nc', '-n', GetoptLong::NO_ARGUMENT],
                   ['--preescape', '--pe', GetoptLong::NO_ARGUMENT],
                   ['--content-mode', '--mode', GetoptLong::REQUIRED_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--username"
    user = arg.to_s
  when "--password"
    pass = arg.to_s
  when "--target_url"
    target_url = arg.to_s
  when "--title"
    title = arg.to_s
  when "--body"
    body = arg.to_s
  when "--config"
    configfile = arg.to_s
  when "--html"
    format = 'html'
  when "--hnf"
    format = 'hnf'
  when "--nocheck"
    check = false
  when "--preescape"
    preescape = true
  when "--content-mode"
    content_mode = arg.to_s
  when "--help"
    usage
  else
    usage
  end
end

begin
  if configfile
    fconf = open(configfile, "r")
  else
    fconf = open("#{ENV['HOME']}/.donrails/atompost.yaml", "r")
  end
  conf = YAML::load(fconf)
  user = conf['user'] unless user
  pass = conf['pass'] unless pass
  target_url = conf['target_url'] unless target_url
rescue
  p $!
end

ap = AtomPost.new

if (body and title)
  ap.atompost(target_url, user, pass, title, body, nil, nil, nil, check, preescape, content_mode)
end

ARGV.each do |f|
  if (format == 'hnf' or (f =~ /d\d{8}.hnf/))
    ap.addhnf(target_url, user, pass, f, check, preescape, content_mode, nil)
  elsif (format == 'html' or (f =~ /.html?/i))
    ap.addhtml(target_url, user, pass, f, check, preescape, content_mode, nil)
  else
    ap.addguess(target_url, user, pass, f, check, preescape, content_mode, nil)
  end
end
