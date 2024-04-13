# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'pony'

Pbm::Application.load_tasks

desc 'Move region contents'
task move_region_contents: :environment do
  ARGV.each { |a| task a.to_sym }
  from_region_name = ARGV[1].to_s
  to_region_name = ARGV[2].to_s

  from_region = Region.find_by_name(from_region_name)
  to_region = Region.find_by_name(to_region_name)

  unless from_region && to_region
    print("INVALID FROM AND/OR TO REGION\n")
    exit(0)
  end

  from_region.move_to_new_region(to_region)

  print("Moved #{from_region_name} to #{to_region_name}\n")
end
