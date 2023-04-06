require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pbm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Pacific Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.serve_static_files = true
    config.assets.initialize_on_precompile = false
    config.assets.version = '1.4'

    config.assets.precompile = ["manifest.js"]

    config.rakismet.key = ENV['RAKISMET_KEY']
    config.rakismet.url = 'https://pinballmap.com/'

    config.middleware.use Rack::Attack
  end
end
