locations = Location.create([
  {:name => 'Bar Cleo', :street => '123 Pine', :city => 'Portland', :state => 'OR', :zip => 97211, :lat => 45.5589, :lon => -122.645, :zone => Zone.create(:name => 'Downtown')},
  {:name => 'Sassington', :street => '456 Wellington', :city => 'Portland', :state => 'OR', :zip => 97212,  :lat => 45.5155, :lon => -122.666, :zone => Zone.create(:name => 'NE')},
  {:name => 'Bawb Town', :street => '789 Beef', :city => 'Hillsboro', :state => 'OR', :zip => 97200,  :lat => 45.5155, :lon => -122.766, :zone => Zone.create(:name => 'SE')},
  {:name => 'Zeldaham', :street => '012 Foo', :city => 'Beaverton', :state => 'OR', :zip => 97211,  :lat => 45.5355, :lon => -122.666},
])

machines = Machine.create([{:name => 'Medieval Madness'}, {:name => 'Fish Tales'}])

LocationMachineXref.create(:location => locations.first, :machine => machines.first)
LocationMachineXref.create(:location => locations.first, :machine => machines.last)
LocationMachineXref.create(:location => locations.last, :machine => machines.first)
