class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
end
