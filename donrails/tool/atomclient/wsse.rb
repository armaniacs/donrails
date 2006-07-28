## wsse.rb
##    written by ARAKI Yasuhiro <yasu@debian.or.jp>
##    License: GPL2

require 'time'
require 'digest/sha1'
require 'base64'

class WSSE
  def initialize
  end

  def generate(user, pass)
    created = Time.now.iso8601
    nonce = open("/dev/random").read(20).unpack("H*").first
    pd = Digest::SHA1.digest(nonce + created + pass)
    wsse = "UsernameToken Username=\"#{user}\", PasswordDigest=\"#{Base64.encode64(pd).chomp}\", Created=\"#{created}\", Nonce=\"#{Base64.encode64(nonce).chomp}\""
  end
  
  def match(wsse)
    logger.info(wsse)
    user = ''
    pass = ''
    nonce = ''
    if wsse =~ (/UsernameToken Username="(\w+)"/)
      user = $1
      aris = Author.find(:first, :conditions => ["name = ?", user])
      return false if aris == nil
      pass = aris.pass
    end
    if wsse =~ (/Created="(\S+)"/)
      created = $1
    end
    if wsse =~ (/PasswordDigest="(\S+)"/)
      passdigest = Base64.decode64($1)
    end
    if wsse =~ (/Nonce="(\S+)"/)
      nonce = Base64.decode64($1)
    end
    pd = Digest::SHA1.digest(nonce + created + pass)
    if pd == passdigest
      return true
    else
      return false
    end
  end
end ## class WSSE
