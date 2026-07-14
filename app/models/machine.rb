require "json"
class Machine < ApplicationRecord
  has_paper_trail
  belongs_to :location_machine_xref, optional: true
  belongs_to :machine_group, optional: true
  has_many :machine_score_xref

  validates_presence_of :name

  def name_and_year
    name + year_and_manufacturer
  end

  def year_and_manufacturer
    (year.blank? && manufacturer.blank? ? "" : " (#{[ manufacturer, year ].reject(&:blank?).join(', ')})")
  end

  MOBILE_CACHE_KEY = "api/v1/machines/no_details"
  MOBILE_CACHE_KEY_WITH_LMX_COUNT = "api/v1/machines/no_details/lmx_count"

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

  after_commit -> { Rails.cache.delete(MOBILE_CACHE_KEY); Rails.cache.delete(MOBILE_CACHE_KEY_WITH_LMX_COUNT) }

  def massaged_name
    name.sub(/^the /i, "")
  end

  SORT_OPTIONS = %w[alphabetical year_newest year_oldest rarest most_common manufacturer not_in_life_list].freeze

  def self.sort_key(machine, sort, life_list_machine_ids = Set.new)
    case sort
    when "year_newest"
      [ -machine.year, machine.massaged_name ]
    when "year_oldest"
      [ machine.year, machine.massaged_name ]
    when "rarest"
      [ machine.lmx_count, machine.massaged_name ]
    when "most_common"
      [ -machine.lmx_count, machine.massaged_name ]
    when "manufacturer"
      [ machine.manufacturer, machine.massaged_name ]
    when "not_in_life_list"
      [ life_list_machine_ids.include?(machine.id) ? 1 : 0, machine.massaged_name ]
    else
      [ machine.massaged_name ]
    end
  end

  # Builds [text, value, html_attrs] triples for options_for_select, with data
  # attributes a select2 `sorter` can read to re-sort client-side without a round trip.
  def self.select_option_data(selected_ids = [], disabled_ids = [])
    selected_ids = Array(selected_ids).map(&:to_s)
    disabled_ids = Array(disabled_ids).map(&:to_s)
    Machine.all.sort_by(&:massaged_name).map do |m|
      [
        m.name_and_year,
        m.id,
        {
          selected: selected_ids.include?(m.id.to_s),
          disabled: disabled_ids.include?(m.id.to_s),
          data: {
            year: m.year,
            manufacturer: m.manufacturer,
            lmx_count: m.lmx_count,
            massaged_name: m.massaged_name
          }
        }
      ]
    end
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

      primary = r["images"].find { |g| g["primary"] && g["type"] == "backglass" } ||
                r["images"].find { |g| g["primary"] }

      if primary
        m.opdb_img = primary["urls"]["medium"]
        m.opdb_img_height = primary["sizes"]["medium"]["height"]
        m.opdb_img_width = primary["sizes"]["medium"]["width"]
      end
      m.save
    end
  end
end
