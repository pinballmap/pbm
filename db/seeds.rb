# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
#

locations = Location.create([
  {:name => 'Bar Cleo', :street => '123 Pine', :city => 'Portland', :state => 'OR', :zip => 97211, :lat => 45.5589, :lon => -122.645},
  {:name => 'Sassington', :street => '456 Wellington', :city => 'Portland', :state => 'OR', :zip => 97212,  :lat => 45.5155, :lon => -122.666},
])
machines = Machine.create([{:name => 'Medieval Madness'}, {:name => 'Fish Tales'}])

LocationMachineXref.create(:location => locations.first, :machine => machines.first)
LocationMachineXref.create(:location => locations.first, :machine => machines.last)
LocationMachineXref.create(:location => locations.last, :machine => machines.first)
