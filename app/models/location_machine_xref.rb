class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  has_many :machine_score_xrefs
end
