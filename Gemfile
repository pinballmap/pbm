source "https://rubygems.org"
ruby "4.0.7"

gem "pg"
gem "rails", "~> 8.1.2"

gem "apipie-rails"
gem "aws-sdk-s3"
gem "browser"
gem "cancancan"
gem "chartkick"
gem "country_select"
gem "devise"
gem "dotenv"
gem "exception_notification"
gem "geocoder"
gem "groupdate"
gem "haml-rails"
gem "has_scope"
gem "active_storage_validations"
gem "image_processing"
gem "kaminari"
gem "maxminddb"
gem "pagy"
gem "paper_trail"
gem "paper_trail-association_tracking"
gem "phonelib"
gem "puma"
gem "rack"
gem "rack-attack"
gem "rails_admin"
gem "rake"
gem "ruby-vips"
gem "sassc-rails"
gem "scout_apm"
gem "solid_cache", "~> 1.0"
gem "solid_queue", "~> 1.1"
gem "sprockets-rails"
gem "strip_attributes"
gem "tzinfo-data"

group :production, :development, :staging do
  gem "rails_semantic_logger"
end

group :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "rspec-retry"
  gem "rubocop"
  gem "selenium-webdriver"
  gem "simplecov"
  gem "simplecov-cobertura"
  gem "timecop"
end

group :development, :test do
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  gem "database_cleaner"
  gem "debug", require: false
  gem "derailed_benchmarks"
  gem "ostruct" # suppress deprecation warning for pry
  gem "rubocop-rails-omakase", require: false
  gem "pry"
end
