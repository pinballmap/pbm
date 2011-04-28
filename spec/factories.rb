Factory.define :location do |l|
  l.name 'Test Location Name'
  l.street '123 Pine'
  l.city 'Portland'
  l.state 'OR'
  l.zip '97211'
  l.lat 45.5589
  l.lon -122.645
  l.association :region, :name => 'portland'
end

Factory.define :machine do |m|
  m.name 'Test Machine Name'
end

Factory.define :location_machine_xref do |lmx|
  lmx.association :location
  lmx.association :machine
end

Factory.define :location_type do |lt|
  lt.name 'Test Location Type'
end

Factory.define :zone do |z|
  z.name 'Test Zone'
end

Factory.define :region do |r|
  r.name 'Test Region'
end

Factory.define :machine_score_xref do |msx|
  msx.association :location_machine_xref
  msx.association :user
end

Factory.define :event do |e|
  e.name 'Test Event'
end

Factory.define :user do |u|
  u.initials 'cap'
  u.sequence(:email) {|n| "captainamerica#{n}@foo.bar"}
  u.password 'password'
  u.association :region, :name => 'portland'
end

Factory.define :location_picture_xref do |lpx|
  lpx.association :location
  lpx.association :user
  lpx.photo File.open(File.join(Rails.root, '/public/images/favicon.ico'))
end

Factory.define :region_link_xref do |rlx|
  rlx.name 'Test Link Name'
  rlx.description 'This is a test link'
  rlx.url 'http://www.foo.com'
  rlx.category 'Test Category'
  rlx.association :region
end
