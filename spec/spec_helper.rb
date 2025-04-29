# rubocop:disable Style/MixinUsage
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] = 'test'
ENV['AWS_REGION'] = 'us-west-1'
require File.expand_path('../../config/environment', __FILE__)
require 'factory_bot_rails'
require 'rspec/rails'
require 'capybara/rspec'
require 'simplecov'
require 'simplecov-cobertura'
require 'rspec/retry'
require 'selenium/webdriver'

include Sprockets::Rails::Helper
include ActiveSupport::Testing::TimeHelpers

SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.around :each, :js do |ex|
    ex.run_with_retry retry: 3
  end

  service = Selenium::WebDriver::Service.chrome
  if ENV.fetch('CHROME_SERVICE_PATH', false) # rubocop:disable Style/IfUnlessModifier
    service.executable_path = File.expand_path(ENV.fetch('CHROME_SERVICE_PATH'))
  end

  Capybara.register_driver :selenium_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    unless ENV.fetch('NO_HEADLESS_CHROME', false)
      options.add_argument('--headless')
      options.add_argument('--window-size=2000,1000')
    end

    options.add_argument('--disable-gpu')

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options,
      service: service
    )
  end

  Capybara.javascript_driver = :selenium_chrome

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerHelpers, type: :controller
  config.include FeatureHelpers, type: :feature

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction

    Geocoder.configure(lookup: :test)
    Geocoder::Lookup::Test.add_stub(
      '97202', [
      {
        'latitude'     => 45.51258500000001,
        'longitude'    => -122.617788,
        'address'      => 'Portland, OR 97202, USA',
        'state'        => 'Oregon',
        'state_code'   => 'OR',
        'country'      => 'United States',
        'country_code' => 'US'
      }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      '97203', [
      {
        'latitude'     => 45.6008356,
        'longitude'    => -122.760606,
        'address'      => 'Portland, OR 97203, USA',
        'state'        => 'Oregon',
        'state_code'   => 'OR',
        'country'      => 'United States',
        'country_code' => 'US'
      }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      '303 Southeast 3rd Avenue, Portland, OR, 97214', [
      {
        'latitude'     => 45.52068740000001,
        'longitude'    => -122.6630702,
        'address'      => '303 SE 3rd Ave, Portland, OR 97214, USA',
        'state'        => 'Oregon',
        'state_code'   => 'OR',
        'country'      => 'United States',
        'country_code' => 'US'
      }
      ]
    )
  end

  config.before(js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    Rails.cache.clear
    DatabaseCleaner.clean
    Warden.test_reset!
  end
end

Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  User.find(id)
end
# rubocop:enable Style/MixinUsage
