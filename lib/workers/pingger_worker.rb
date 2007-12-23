class PinggerWorker < BackgrounDRb::MetaWorker
  set_worker_name :pingger_worker

  attr :verbose, true
  attr :numbers, true
  attr :defer_seconds, true
  attr :unsave, true
  attr :force, true
  attr :type, true

  def create(args = nil)
    # this method is called, when worker is loaded for the first time
    @verbose = nil
    @unsave = nil
    @force = nil
    @type = nil
    @numbers = 10
    @defer_seconds = 600
    puts "Starting pingger_worker"
  end

  def async_send
    if @force
      pings = DonPing.find(:all, :limit => @numbers,:order => "id DESC")
    elsif @defer_seconds
      pings = DonPing.find(:all, :conditions => ["counter = 0 OR (counter < 10 AND created_at + INTERVAL '?' * POW(2, counter) SECOND < NOW() AND ( send_at IS NULL OR NOT status = 'success' ))", @defer_seconds],
                           :limit => @numbers,
                           :order => "id DESC"
                           )
    else
      pings = DonPing.find(:all, :conditions => ["send_at IS NULL OR NOT status = 'success'"],
                           :limit => @numbers,
                           :order => "id DESC"
                           )
    end
    puts 'Number of ping(s) is ' + pings.length.to_s if @verbose
    pings.each do |ping|
      pingok, rbody = ping.send_ping2a(@type)
      ping.counter += 1

      if pingok
        ping.send_at = Time.now
        ping.status = 'success'
      else
        ping.status = 'error'
        puts 'ping error'
        puts rbody if @verbose
      end
      if rbody
        ping.response_body = rbody
      end
      puts ping.url
      puts ping.url if @verbose
      if @unsave
        puts 'skip DonPing.save' if @verbose
      else
        ping.save 
      end
    end
  end

end

