if Rails.env.production?
    Rack::Attack.blocklist('block bad UA') do |req|
      req.user_agent == 'SemrushBot'
    end

    Rack::Attack.throttle('req/ip', :limit => 100, :period => 10.seconds) do |req|
      req.ip
    end
end
