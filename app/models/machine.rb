class Machine < ActiveRecord::Base
  belongs_to :location_machine_xref
  belongs_to :machine_group

  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }

  validates_presence_of :name

  attr_accessible :name, :ipdb_link, :year, :manufacturer, :machine_group_id

  def name_and_year
    name + year_and_manufacturer
  end

  def year_and_manufacturer
    ((year.blank? && manufacturer.blank?) ? '' : " (#{[manufacturer, year].reject(&:blank?).join(', ')})")
  end

  before_destroy do |record|
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where machine_id = #{record.id})"
    LocationMachineXref.destroy_all "machine_id = #{record.id}"
  end

  def massaged_name
    name.sub(/^the /i, '')
  end

  def all_machines_in_machine_group
    machine_group_id ? Machine.where('machine_group_id = ?', machine_group_id).to_a : [self]
  end
end
