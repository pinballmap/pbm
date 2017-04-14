if Rails.env.production?
    Rack::Attack.blocklist('block admin identified IPs') do |req|
      should_ban = nil

      BannedIp.all.each do |banned_ip|
        if (banned_ip.ip_address == req.ip)
          should_ban = 1
        end
      end

      should_ban
    end

    Rack::Attack.blocklist('block bad UA') do |req|
      req.user_agent == 'SemrushBot'
    end

    (1..5).each do |level|
      Rack::Attack.throttle('req/ip/#{level}', :limit => (40 * level), :period => (8 ** level).seconds) do |req|
        req.ip
      end
    end
end
