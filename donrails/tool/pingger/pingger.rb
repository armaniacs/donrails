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
unsave = nil
force = nil
numbers = 10

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

 -n numbers\t: set number of ping article (default:10)

 -u\t: unsave. When use this option, you do not run DonPing.save.

 --force\t: force. When use this option, force send ping even for already sent.
"
  exit
end

parser.set_options(
                   ['--numbers', '-n', GetoptLong::REQUIRED_ARGUMENT],
                   ['--mode', '-m', GetoptLong::REQUIRED_ARGUMENT],
                   ['--config', '-f', GetoptLong::REQUIRED_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT],
                   ['--development', '-d', GetoptLong::NO_ARGUMENT],
                   ['--production', '-p', GetoptLong::NO_ARGUMENT],
                   ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
                   ['--unsave', '-u', GetoptLong::NO_ARGUMENT],
                   ['--force', GetoptLong::NO_ARGUMENT],
                   ['--test', '-t', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--force"
    force = true
  when "--unsave"
    unsave = true
  when "--numbers"
    numbers = arg.to_i
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
require File.dirname(__FILE__) + '/../../../rails/config/environment'

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
  belongs_to :enrollment
end
class Category < ActiveRecord::Base
  has_and_belongs_to_many :articles, :join_table => "categories_articles"
end
require File.dirname(__FILE__) + '/../../../rails/app/models/don_ping.rb'
require File.dirname(__FILE__) + '/../../../rails/app/models/don_env.rb'
require File.dirname(__FILE__) + '/../../../rails/app/models/enrollment.rb'
def don_get_config
  DonEnv.find(:first, :conditions => ["hidden IS NULL OR hidden = 0"])
end

class Pingger
  attr :verbose, true
  attr :numbers, true
  attr :unsave, true
  attr :force, true

  def initialize
    @verbose = nil
    @unsave = nil
    @force = nil
    @numbers = 10
    @slog = Syslog.open(__FILE__,
                        Syslog::Constants::LOG_PID |
                        Syslog::Constants::LOG_CONS,
                        Syslog::Constants::LOG_DAEMON)
  end

  def async_send
    if @force
      pings = DonPing.find(:all, :limit => @numbers,:order => "id DESC")
    else
      pings = DonPing.find(:all, :conditions => ["send_at IS NULL"],
                           :limit => @numbers,
                           :order => "id DESC"
                           )
    end
    puts 'Number of ping(s) is ' + pings.length.to_s if @verbose
    pings.each do |ping|
      ping.send_ping2a
      ping.send_at = Time.now
      @slog.info ping.url
      puts ping.url if @verbose
      if @unsave
        puts 'skip DonPing.save' if @verbose
      else
        ping.save 
      end
    end
  end

end

pg = Pingger.new
pg.verbose = true if verbose
pg.unsave = true if unsave
pg.force = true if force
pg.numbers = numbers
pg.async_send
