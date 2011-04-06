class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  belongs_to :operator
  has_many :machine_score_xrefs

  scope :region, lambda {|name| 
    r = Region.find_by_name(name)
    joins(:location).where('locations.region_id = ?', r.id)
  }

  def haml_object_ref
    'lmx'
  end
end
