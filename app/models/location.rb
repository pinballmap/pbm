class Location < ActiveRecord::Base
  validates_presence_of :name, :street, :city, :state, :zip
  has_many :location_machine_xrefs
  belongs_to :region
  belongs_to :zone

  scope :by_location_id, lambda {|id| where(:id => id)}
  scope :by_zone_id, lambda {|id| where(:zone_id => id)}
  scope :by_city, lambda {|city| where(:city => city)}
  scope :by_location_name, lambda {|name| where(:name => name)}
  scope :by_machine_id, lambda {|id|
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', id)
  }
  scope :by_machine_name, lambda {|name|
    machine = Machine.find(:all, :conditions => ['name = ?', name]).first
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', machine.id)
  }

  def machine_names
    LocationMachineXref.find_all_by_location_id(self.id).collect! { |lmx| lmx.machine.name }.sort
  end
end
