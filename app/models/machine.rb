class Machine < ActiveRecord::Base
  belongs_to :location_machine_xref
  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }

  validates_presence_of :name

  def name_and_year
    name + ((year.blank? && manufacturer.blank?) ? '' : " (#{[manufacturer, year].reject(&:blank?).join(', ')})")
  end

  before_destroy do |record|
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where machine_id = #{record.id})"
    LocationMachineXref.destroy_all "machine_id = #{record.id}"
  end

  def massaged_name
    name.sub(/^the /i,"")
  end
end
