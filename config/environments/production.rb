require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = ENV['ASSET_HOST']

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :amazon
  config.active_storage.variant_processor = :vips

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  # config.log_tags = [ :request_id ]
  # config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.colorize_logging = false

  config.rails_semantic_logger.add_file_appender = false
  config.rails_semantic_logger.format = :default
  config.rails_semantic_logger.quiet_assets = true
  config.semantic_logger.add_appender(
    io: STDOUT,
    level: config.log_level,
    formatter: config.rails_semantic_logger.format
  )

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id, lambda { |request| request.ip }, lambda { |request| request.headers['AppVersion'] }, lambda { |request| request.user_agent } ]

  # Log to STDOUT by default
  # config.logger = ActiveSupport::Logger.new(STDOUT)
  # .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
  # .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  config.action_mailer.smtp_settings = {
    address:          'mail.smtp2go.com',
    port:             587,
    authentication:   'plain',
    user_name:        'pinballmapsmtp2go',
    password:         ENV['SMTP2GO_API_KEY'],
    domain:           'pinballmap.com',
    enable_starttls:  true,
    open_timeout:     5,
    read_timeout:     10
  }
  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { :protocol => 'https', :host => 'pinballmap.com' }
  config.middleware.use ExceptionNotification::Rack,
    ignore_crawlers: %w{Googlebot bingbot AhrefsBot},
    ignore_exceptions: ['ActionController::ParameterMissing', 'ActionView::Template::Error', 'ActionDispatch::Http::MimeNegotiation::InvalidType', 'ActionController::TooManyRequests'] + ExceptionNotifier.ignored_exceptions,
    :email => {
      :email_prefix => "[PBM Exception] ",
      :sender_address => %{"PBM Exceptions" <exceptions@pinballmap.com>},
      :exception_recipients => %w{admin@pinballmap.com}
    },
    error_grouping: true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
    req = payload[:request]
    if req.env["rack.attack.match_type"] == :blocklist
      Rails.logger.info "[Rack::Attack][Blocked]" <<
                        "remote_ip: \"#{req.ip}\"," <<
                        "path: \"#{req.path}\", "
    end
  end
end
