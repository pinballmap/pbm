unless Rails.env.test?

  (1..10).each do |level|
    Rack::Attack.throttle('req/ip/#{level}', :limit => (100 * level), :period => (10 * level).seconds) do |req|
      req.ip
    end
  end

  Rack::Attack.throttle('logins/ip', limit: 6, period: 20.seconds) do |req|
    if req.path == '/users/login' && req.post?
      req.ip
    end
  end

  Rack::Attack.blocklist('block admin identified IPs') do |req|
    should_ban = nil

    BannedIp.all.each do |banned_ip|
      if (banned_ip.ip_address == req.ip)
        should_ban = 1
      end
    end

    should_ban
  end
end
