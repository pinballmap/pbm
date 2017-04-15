namespace :rubocop do
  task :run do
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new
  end
end

desc 'Run RuboCop to check style guide compliance'
task rubocop: 'rubocop:run'

task default: :rubocop
