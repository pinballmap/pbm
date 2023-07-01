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

  # Blocklist malicious IP addresses
  Rack::Attack.blocklist_ip("185.11.61.144")
  Rack::Attack.blocklist_ip("23.95.173.12")

end
