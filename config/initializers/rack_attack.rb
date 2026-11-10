ESCALATING_BAN_TIERS = [
  { maxretry: 1, findtime: 1.minute,   bantime: 3.minute   },
  { maxretry: 3, findtime: 15.minutes, bantime: 30.minutes },
  { maxretry: 5, findtime: 30.minutes, bantime: 3.hours     }
].freeze

ESCALATING_BAN_NAMES = %w[users_profile pages_recent_activity maps_general maps_region bot locations_render_location_detail_sustained locations_render_machines_sustained maps_post_load non_xhr].freeze

# Mirrors the check that raises ActionDispatch::RemoteIp::IpSpoofAttackError
def spoofed_client_ip?(req)
  client_ip = req.get_header("HTTP_CLIENT_IP").to_s.split(",").first&.strip
  forwarded_ips = req.get_header("HTTP_X_FORWARDED_FOR").to_s.split(",").map(&:strip)
  client_ip.present? && forwarded_ips.any? && !forwarded_ips.include?(client_ip)
end

unless Rails.env.test?
  Rack::Attack.throttle("api/v1/no-app-version", limit: 180, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/") && req.env["HTTP_APPVERSION"].blank?
      req.ip
    end
  end

  Rack::Attack.blocklist("fail2ban pentesters") do |req|
    Rack::Attack::Fail2Ban.filter(
      "pentesters-#{req.ip}",
      maxretry: 1,
      findtime: 10.minutes,
      bantime: 3.hours
    ) do
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      CGI.unescape(req.query_string) =~ %r{page=\D} ||
      CGI.unescape(req.query_string) =~ /(?:\A|&)(?:by_at_least_n_machines\w*|by_machine_year_[gl]te|by_operator_id|by_type_id(?:\[\])?)=[^\d&]/ ||
      req.path.include?("/etc/passwd") ||
      req.path.include?("wp-admin") ||
      req.path.include?("wp-login") ||
      req.path.include?("wp-includes") ||
      req.path.include?("poohbear") ||
      req.path.include?("sleep(") ||
      req.path.include?(".php") ||
      req.path.include?(".env") ||
      spoofed_client_ip?(req)
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

  Rack::Attack.blocklist("escalating repeat offenders") do |req|
    ESCALATING_BAN_TIERS.any? do |tier|
      Rack::Attack::Fail2Ban.banned?("repeat-offender-#{tier[:bantime].to_i}-#{req.ip}")
    end
  end
end
