#!/usr/bin/evn ruby

## Author: ARAKI Yasuhiro <yasu@debian.or.jp>
## Copyright: 2007 ARAKI Yasuhiro
##
## Usage and Detail:
##  see http://code.google.com/p/donrails/wiki/PinggerIntroduction

require 'syslog'
require 'getoptlong'
parser = GetoptLong.new
mode = 'production'
config = ''
verbose = nil

def usage
    puts "
pingger.rb [options]

Available options:

 -m mode\t: Usually use 'mode' options. Like
\t\t ruby pingger.rb -m production \t(production mode is default.)

 -p\t: Same as 'ruby pingger.rb -m production'

 -d\t: Same as 'ruby pingger.rb -m development'

 -t\t: Same as 'ruby pingger.rb -m test'

 -h\t: Show this message.

 -f filename\t: configuration file.

 -v\t: verbose output
"
  exit
end

parser.set_options(
                   ['--mode', '-m', GetoptLong::REQUIRED_ARGUMENT],
                   ['--config', '-f', GetoptLong::REQUIRED_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT],
                   ['--development', '-d', GetoptLong::NO_ARGUMENT],
                   ['--production', '-p', GetoptLong::NO_ARGUMENT],
                   ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
                   ['--test', '-t', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--mode"
    mode = arg.to_s
  when "--development"
    mode = 'development'
  when "--production"
    mode = 'production'
  when "--test"
    mode = 'test'
  when "--config"
    config = arg.to_s
  when "--verbose"
    verbose = true
  when "--usage"
    usage
  else
    usage
  end
end

require 'xmlrpc/client'
require File.dirname(__FILE__) + '/../../../rails/vendor/activerecord/lib/active_record'

if config != ''
  fconf = open(config, "r")
else
  begin
    fconf = open("#{ENV['HOME']}/.donrails/pingger.yml", "r")
  rescue
    fconf = open("#{File.dirname(__FILE__)}/../../../rails/config/database.yml", "r")
  end
end
conf = YAML::load(fconf)

ActiveRecord::Base.establish_connection(conf["#{mode}"])

class Article < ActiveRecord::Base
  has_and_belongs_to_many :categories, :join_table => "categories_articles"
end
class Category < ActiveRecord::Base
  has_and_belongs_to_many :articles, :join_table => "categories_articles"
end

require File.dirname(__FILE__) + '/../../../rails/app/models/don_ping.rb'
require File.dirname(__FILE__) + '/../../../rails/app/models/don_env.rb'
def don_get_config
  DonEnv.find(:first, :conditions => ["hidden IS NULL OR hidden = 0"])
end

class Pingger
  attr :verbose, true

  def initialize
    @verbose = nil
    @slog = Syslog.open(__FILE__,
                        Syslog::Constants::LOG_PID |
                        Syslog::Constants::LOG_CONS,
                        Syslog::Constants::LOG_DAEMON)
  end

  def async_send
    pings = DonPing.find(:all, :conditions => ['send_at IS NULL'])
    puts 'Number of ping(s) is ' + pings.length.to_s if @verbose
    pings.each do |ping|
      ping.send_ping2a
      ping.send_at = Time.now
      @slog.info ping.url
      puts ping.url if @verbose
      ping.save
    end
  end

end

pg = Pingger.new
pg.verbose = true if verbose
pg.async_send
