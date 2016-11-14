if Rails.env.production?
    Rack::Attack.blacklist('block admin identified IPs') do |req|
      should_ban = nil

      BannedIp.all.each do |banned_ip|
        if (banned_ip.ip_address == req.ip)
          should_ban = 1
        end
      end

      should_ban
    end

    Rack::Attack.throttle('req/ip', :limit => 10, :period => 1.second) do |req|
      req.ip
    end
end
