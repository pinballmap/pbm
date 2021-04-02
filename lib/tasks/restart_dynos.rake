namespace :heroku do
  desc 'Restart heroku dynos'
  task restart_dynos: :environment do
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
    dynos =  heroku.dyno.list(ENV['HEROKU_APP_NAME'])

    heroku.dyno.restart(ENV['HEROKU_APP_NAME'], dynos[0]['name'])
  end
end
