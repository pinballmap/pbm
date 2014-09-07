regions = Region.create([
  { name: 'portland', full_name: 'Portland' },
  { name: 'chicago', full_name: 'Chicago' }
])

User.create([
  { region: regions.first, username: 'pdx', password: 'password', password_confirmation: 'password', email: 'scott.wainstock@gmail.com' },
  { region: regions.last, username: 'chicago', password: 'password', password_confirmation: 'password', email: 'baron.von.awesome@gmail.com' }
])

locations = Location.create([
  { region: regions.first, name: 'Bar Cleo', street: '123 Pine', city: 'Portland', state: 'OR', zip: '97211', lat: 45.5589, lon: -122.645, zone: Zone.create(name: 'Downtown', region: regions.first) },
  { region: regions.first, name: 'Sassington', street: '456 Wellington', city: 'Portland', state: 'OR', zip: '97212',  lat: 45.5155, lon: -122.666, zone: Zone.create(name: 'NE', region: regions.first) },
  { region: regions.first, name: 'Bawb Town', street: '789 Beef', city: 'Hillsboro', state: 'OR', zip: '97200',  lat: 45.5155, lon: -122.766, zone: Zone.create(name: 'SE', region: regions.first) },
  { region: regions.first, name: 'Zeldaham', street: '012 Foo', city: 'Beaverton', state: 'OR', zip: '97211', lat: 45.5355, lon: -122.666 }
])

machines = Machine.create([{ name: 'Medieval Madness' }, { name: 'Fish Tales' }])

LocationMachineXref.create(location: locations.first, machine: machines.first)
LocationMachineXref.create(location: locations.first, machine: machines.last)
LocationMachineXref.create(location: locations.last, machine: machines.first)

Event.create([
  { region: regions.first, name: 'A Cool event', long_desc: 'This is a super long description of cool stuff', link: 'http://crazyflipperfingers.com/talk', category_no: 1, start_date: '2011-04-08', end_date: '2011-04-10', location: locations.first }
])
