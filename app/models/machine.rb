class Machine < ApplicationRecord
  belongs_to :location_machine_xref, optional: true
  belongs_to :machine_group, optional: true

  scope :by_name, (proc { |name| where(:name.matches => "%#{name}%") })

  validates_presence_of :name

  def name_and_year
    name + year_and_manufacturer
  end

  def year_and_manufacturer
    (year.blank? && manufacturer.blank? ? '' : " (#{[manufacturer, year].reject(&:blank?).join(', ')})")
  end

  before_destroy do |record|
    MachineScoreXref.where("location_machine_xref_id in (select id from location_machine_xrefs where machine_id = #{record.id})").destroy_all
    LocationMachineXref.where(machine_id: record.id).destroy_all
  end

  def massaged_name
    name.sub(/^the /i, '')
  end

  def all_machines_in_machine_group
    machine_group_id ? Machine.where('machine_group_id = ?', machine_group_id).to_a : [self]
  end
end
