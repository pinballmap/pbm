require 'json'
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

  def self.tag_with_opdb_json(opdb_json)
    JSON.parse(opdb_json).each do |r|
      m = Machine.find_by_opdb_id(r['opdb_id'])
      next unless m

      primary = r["images"].find { |g| g["primary"] }

      if primary
        m.opdb_img = primary["urls"]["medium"]
        m.opdb_img_height = primary["sizes"]["medium"]["height"]
        m.opdb_img_width = primary["sizes"]["medium"]["width"]
      end
      m.save
    end
  end
end
