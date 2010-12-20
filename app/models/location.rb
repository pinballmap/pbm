class Location < ActiveRecord::Base
  has_many :location_machine_xrefs
#  scope :by_name, proc { |name| { :conditions => { :name => name }}}

  validates_presence_of :name, :street, :city, :state, :zip

  def machine_names
    self.location_machine_xrefs.collect! { |lmx| lmx.machine ? lmx.machine.name : 'MACHINELESS XREF!' }.sort
  end

  def self.search(location_name, location_id)
    if !location_id.empty?
      where('id = ?', location_id)
    elsif location_name
      where('name LIKE ?', "%#{location_name}%")
    else
      scoped
    end
  end
end
