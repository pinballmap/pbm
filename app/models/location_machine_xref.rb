class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  belongs_to :operator
  has_many :machine_score_xrefs

  def haml_object_ref
    'lmx'
  end
end
