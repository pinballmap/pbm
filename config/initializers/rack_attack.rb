unless Rails.env.test?

  (1..10).each do |level|
    Rack::Attack.throttle('req/ip/#{level}', :limit => (120 * level), :period => (10 * level).seconds) do |req|
      req.ip
    end
  end  

end
