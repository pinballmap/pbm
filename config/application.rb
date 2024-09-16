require_relative "boot"
require_relative '../lib/middleware/semicolon_handling'

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pbm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
		
    # Please, add to the `ignore` list any other `lib` subdirectories that do
		# not contain `.rb` files, or that should not be reloaded or eager loaded.
		# Common ones are `templates`, `generators`, or `middleware`, for example.
		config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Pacific Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.schema_format = :sql

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.serve_static_files = true
    config.assets.initialize_on_precompile = false
    config.assets.version = '1.4'

    config.assets.precompile = ["manifest.js"]

    config.middleware.insert_after Rack::Runtime, ReplaceSemicolonWithAmpersand
  end
end
