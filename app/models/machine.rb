require "json"
class Machine < ApplicationRecord
  has_paper_trail
  belongs_to :location_machine_xref, optional: true
  belongs_to :machine_group, optional: true

  validates_presence_of :name

  def name_and_year
    name + year_and_manufacturer
  end

  def year_and_manufacturer
    (year.blank? && manufacturer.blank? ? "" : " (#{[ manufacturer, year ].reject(&:blank?).join(', ')})")
  end

  before_destroy do |record|
    MachineScoreXref.where("location_machine_xref_id in (select id from location_machine_xrefs where machine_id = #{record.id})").destroy_all
    lmxs_to_delete = LocationMachineXref.unscoped.where(machine_id: record.id)
    lmxs_to_delete.each do |lmx|
      lmx.destroy(force: true)
    end
    Status.where(status_type: "machines").update({ updated_at: Time.current })
  end

  before_save do
    Status.where(status_type: "machines").update({ updated_at: Time.current })
  end

  def massaged_name
    name.sub(/^the /i, "")
  end

  def all_machines_in_machine_group
    machine_group_id ? Machine.where("machine_group_id = ?", machine_group_id).to_a : [ self ]
  end

  def self.tag_with_opdb_type_json(opdb_json)
    json = JSON.parse(opdb_json)
    combined_machines = json["machines"] + json["aliases"]
    combined_machines.each do |r|
      m = Machine.find_by_opdb_id(r["opdbId"])
      next unless m

      m.machine_type = r["type"]
      m.machine_display = r["display"]
      m.save
    end
  end

  def self.tag_with_opdb_changelog_json(opdb_json)
    JSON.parse(opdb_json).each do |r|
      m = Machine.find_by_opdb_id(r["opdb_id_deleted"])
      next unless m

      if r["action"] == "move"
        m.opdb_id = r["opdb_id_replacement"]
      elsif r["action"] == "delete"
        m.opdb_id = ""
      end
      m.save
    end
  end

  def self.tag_with_opdb_image_json(opdb_json)
    json = JSON.parse(opdb_json)
    combined_machines = json["machines"] + json["aliases"]
    combined_machines.each do |r|
      m = Machine.find_by_opdb_id(r["opdbId"])
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
