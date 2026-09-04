ESCALATING_BAN_TIERS = [
  { maxretry: 1, findtime: 1.minute,   bantime: 1.minute   },
  { maxretry: 3, findtime: 15.minutes, bantime: 15.minutes },
  { maxretry: 5, findtime: 30.minutes, bantime: 1.hour     }
].freeze

ESCALATING_BAN_NAMES = %w[users_profile pages_recent_activity maps_general maps_region bot].freeze

unless Rails.env.test?
  Rack::Attack.throttle('api/v1/no-app-version', limit: 180, period: 1.minute) do |req|
    if req.path.start_with?('/api/v1/') && req.env['HTTP_APPVERSION'].blank?
      req.ip
    end
  end

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

  ActiveSupport::Notifications.subscribe("rate_limit.action_controller") do |*, payload|
    next unless ESCALATING_BAN_NAMES.include?(payload[:name])

    request = payload[:request]
    next unless request

    ESCALATING_BAN_TIERS.each do |tier|
      Rack::Attack::Fail2Ban.filter("repeat-offender-#{tier[:bantime].to_i}-#{request.ip}", tier) { true }
    end
  end

  Rack::Attack.blocklist('escalating repeat offenders') do |req|
    ESCALATING_BAN_TIERS.any? do |tier|
      Rack::Attack::Fail2Ban.banned?("repeat-offender-#{tier[:bantime].to_i}-#{req.ip}")
    end
  end
end
