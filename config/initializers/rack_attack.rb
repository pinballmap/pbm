unless Rails.env.test?
  Rack::Attack.blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter(
      "pentesters-#{req.ip}",
      maxretry: 1,
      findtime: 10.minutes,
      bantime: 3.hours
    ) do
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      CGI.unescape(req.query_string) =~ %r{page=\D} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      req.path.include?('wp-includes') ||
      req.path.include?('poohbear') ||
      req.path.include?('sleep(') ||
      req.path.include?('.php')
    end
  end
end
