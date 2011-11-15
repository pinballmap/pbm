require 'bundler/capistrano'

set :application, "pinballmap.com"
set :repository,  "git://github.com/scottwainstock/pbm.git"

set :scm, :git

role :web, "pinballmap.com"
role :app, "pinballmap.com"
role :db,  "pinballmap.com", :primary => true

set :user, "thezitremedy"
set :deploy_to, "/home/thezitremedy/work/pbm"
set :bundle_cmd, '/home/thezitremedy/.gems/bin/bundle'
set :use_sudo, false

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
