namespace :heroku do
  desc 'Restart heroku dynos'
  task restart_dynos: :environment do
    heroku = Heroku::API.new.post_ps_restart(ENV['HEROKU_APP_NAME'])
  end
end
