require_relative 'boot'

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pbm
  class Application < Rails::Application
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.serve_static_files = true
    config.assets.initialize_on_precompile = false
    config.assets.version = '1.4'

    # unfortunate inability to use wildcards because of a bug in rails admin
    config.assets.precompile += %w(
      mobile-application.css
      mediaqueries.css
      highslide-ie6.css
      highslide.css
      rails_admin.css
      rails_admin/rails_admin.css
      highslide.min.js
      jquery.form.js
      jquery.remotipart.js
      rails.js
      rails_admin.js
      rails_admin/rails_admin.js
    )

    config.rakismet.key = ENV['RAKISMET_KEY']
    config.rakismet.url = 'https://pinballmap.com/'

    config.middleware.use Rack::Attack
  end
end
