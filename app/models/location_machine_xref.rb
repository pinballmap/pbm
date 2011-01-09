class LocationMachineXref < ActiveRecord::Base
  belongs_to :location, :machine
  has_many :machine_score_xref
end
