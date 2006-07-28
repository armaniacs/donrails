#!/usr/bin/env ruby

# Author: ARAKI Yasuhiro <yasu@debian.or.jp>
# Copyright: (c) 2006 ARAKI Yasuhiro
# Licence: GPL2

require 'yaml'
require 'getoptlong'
require 'atomcheck'
require 'rmail/parser'
require 'nkf'
require 'net/smtp'
require 'htree'

=begin

for test

$ cat ~/Mail/inbox/1115 |ruby atommail.rb  -c ~/.donrails/atompost-test.yaml -n

invoke from .forward

"|/usr/local/bin/atommail.rb -c ~/.donrails/atompost.yaml"

=end

def usage
  print "#{$0}\n\n"
  print "--config or -c=configfile:\n\t Set YAML format config file.\n"
  print "--nocheck\n\t NO CHECK article is already has posted or not. (Default checkd.)\n"
  print "--help\n\t Show this message\n"
  exit
end

# send report to report_mailaddress
def reportmail(report_mailaddress, from_mailaddress, title, reason='Sucess')
  if title
    title = NKF.nkf("-j", title) 
  else
    title = "(no title)"
  end
  msgstr = <<END_OF_MESSAGE
From: reporter
To: #{report_mailaddress}
Subject: receive atompost request
MIME-Version: 1.0
Content-Type: text/plain; charset="ISO-2022-JP"

#{reason}: accept as follows,

Title: #{title}

END_OF_MESSAGE

  Net::SMTP.start('localhost', 25) do |smtp|
    smtp.send_message msgstr, from_mailaddress, report_mailaddress
  end
end

user = nil
pass = nil
mailpass = nil
certify_mailaddress = nil
report_mailaddress = nil
target_url = nil
title = nil
body = nil
configfile = nil
format = nil
check = true
preescape = false
content_mode = nil
category = nil

parser = GetoptLong.new
parser.set_options(['--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
                   ['--nocheck', '--nc', '-n', GetoptLong::NO_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--config"
    configfile = arg.to_s
  when "--nocheck"
    check = false
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
#  mailpass = conf['mailpass'] unless mailpass
  certify_mailaddress = conf['certify_mailaddress'] unless certify_mailaddress
  report_mailaddress = conf['report_mailaddress'] unless report_mailaddress
  target_url = conf['target_url'] unless target_url
  target_url_image = conf['target_url_image'] unless target_url_image
  category = conf['category'] unless category
rescue
  p $!
end

message = RMail::Parser.read(STDIN)
body = ''
bodyhtml = ''

from_mailaddress = message.header.from[0].local + '@' + message.header.from[0].domain
if certify_mailaddress
  unless certify_mailaddress.include?(from_mailaddress) 
    print from_mailaddress + " is not certified address\n"
    reportmail(report_mailaddress, from_mailaddress, title, 'Not certified address.') if report_mailaddress
    exit
  end
end

title = NKF.nkf("-m -w", message.header.subject)
puts NKF.nkf('-e', title)

image = Array.new

## multipart message is not stable...
if message.multipart? and message.header.content_type == "multipart/alternative"
  message.each_part do |mp|
    if mp.header.content_type == "text/html"
      bodyhtml = NKF.nkf("-w", mp.body)
    elsif mp.header.content_type == "text/plain"
      body = NKF.nkf("-w", mp.body)
    end
  end
elsif message.multipart?
  message.each_part do |mp|
    if mp.header.content_type == "text/html"
      bodyhtml = NKF.nkf("-w", mp.body)
    elsif mp.header.content_type == "text/plain"
      body = NKF.nkf("-w", mp.body)
    elsif mp.header.content_type =~ /^image\// then
#      image.push(mp.body)
      image.push(mp)
    end
  end
else
  body = NKF.nkf("-w", message.body)
end

p target_url

## send text 
begin
  ap = AtomPost.new
  if bodyhtml and bodyhtml.length > 0
    res = ap.atompost(target_url, user, pass, title, bodyhtml, nil, category, nil, check, preescape, nil)
  else
    res = ap.atompost(target_url, user, pass, title, body.chomp, nil, category, nil, check, preescape, 'plain')
  end
  br = HTree.parse(res.body).to_rexml
  id = br.root.elements['id'].text
  reportmail(report_mailaddress, from_mailaddress, title, id) if report_mailaddress
rescue
  reportmail(report_mailaddress, from_mailaddress, title, $!) if report_mailaddress
  exit
end

relateid = id

if target_url_image
  image.each do |mp|
    p mp.header.content_type

    if mp.header.match?(/^content-transfer-encoding$/i, /base64/)
      res = ap.atompost(target_url_image, user, pass, title, mp.body, nil, category, mp.header.content_type, check, preescape, 'base64', relateid)
      br = HTree.parse(res.body).to_rexml
      id = br.root.elements['id'].text
      reportmail(report_mailaddress, from_mailaddress, title, id) if report_mailaddress
    end
  end
end
