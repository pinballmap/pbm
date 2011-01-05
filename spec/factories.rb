Factory.define :location do |l|
  l.name 'Test Location Name'
  l.street '123 Pine'
  l.city 'Portland'
  l.state 'OR'
  l.zip '97211'
  l.lat '11'
  l.lon '-122'
end

Factory.define :machine do |m|
  m.name 'Test Machine Name'
end

Factory.define :location_machine_xref do |lmx|
  lmx.association :location
  lmx.association :machine
end

Factory.define :zone do |z|
  z.name 'Test Zone'
end
