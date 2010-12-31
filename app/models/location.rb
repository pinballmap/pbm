class Location < ActiveRecord::Base
  has_many :location_machine_xrefs
  validates_presence_of :name, :street, :city, :state, :zip

  scope :by_location_id, lambda {|id| where(:id => id)}
  scope :by_location_name, lambda {|name| where(:name => name)}
  scope :by_machine_id, lambda {|id|
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', id)
  }

  def machine_names
    self.location_machine_xrefs.collect! { |lmx| lmx.machine ? lmx.machine.name : 'MACHINELESS XREF!' }.sort
  end
end
