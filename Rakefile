# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require File.expand_path('../config/application', __FILE__)
require 'rake'

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

desc 'Create an admin user in development with login as example@example.com and password as example'
task create_developer_account: :environment do
  raise StandardError, 'Development environment required. This operation has been stopped.' unless Rails.env.development?

  user = User.new({ id: nil, email: 'example@example.com', password: 'example', password_confirmation: 'example', region_id: 1, initials: 'exa', is_super_admin: true, username: 'exampleuser', authentication_token: '' })

  begin
    user.save! && user.update!({ confirmed_at: Time.now })
    puts 'User created - username: example@example.com pw: example'
  rescue StandardError => e
    puts 'Problem creating user'
    raise e
  end
end
