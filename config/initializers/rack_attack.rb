unless Rails.env.test?

  (1..10).each do |level|
    Rack::Attack.throttle('req/ip/#{level}', :limit => (100 * level), :period => (5 * level).seconds) do |req|
      req.ip
    end
  end

  Rack::Attack.blocklist('block admin identified IPs') do |req|
    should_ban = nil

    BannedIp.all.each do |banned_ip|
      if (banned_ip.ip_address == req.get_header("CF-CONNECTING-IP"))
        should_ban = 1
      end
    end

    should_ban
  end

  Rack::Attack.blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter(
      "pentesters-#{req.ip}",
      maxretry: 1,
      findtime: 10.minutes,
      bantime: 30.minutes
    ) do
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login')
    end
  end
end
