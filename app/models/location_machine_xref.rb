class LocationMachineXref < ActiveRecord::Base
  has_one :location
  has_one :machine
end
