class Machine < ActiveRecord::Base
  belongs_to :location_machine_xref
  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }

  validates_presence_of :name

  before_destroy do |record|
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where machine_id = #{record.id})"
    LocationMachineXref.destroy_all "machine_id = #{record.id}"
  end
end
