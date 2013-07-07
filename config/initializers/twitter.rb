Twitter.configure do |config|
  config.consumer_key = ENV['twitter_key'],
  config.consumer_secret = ENV['twitter_secret']
  config.oauth_token = ENV['twitter_token']
  config.oauth_token_secret = ENV['twitter_secret_token']
end