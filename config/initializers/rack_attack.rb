if Rails.env.production?
    Rack::Attack.throttle('req/ip', :limit => 100, :period => 10.seconds) do |req|
      req.ip
    end
end
