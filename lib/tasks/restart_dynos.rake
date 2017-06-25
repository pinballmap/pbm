namespace :heroku do
  desc 'Restart heroku dynos'
  task restart_dynos: :environment do
    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).post_ps_restart(ENV['HEROKU_APP_NAME'])
  end
end
