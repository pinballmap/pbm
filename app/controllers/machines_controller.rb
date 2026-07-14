class MachinesController < ApplicationController
  def opdb_img
    machine = Machine.select(:opdb_img, :ic_eligible).find(params[:id])
    render json: { opdb_img: machine.opdb_img.presence, ic_eligible: machine.ic_eligible }
  end

  def autocomplete
    if params[:region_level_search].nil?
      results = Machine.where("clean_items(name) ilike '%' || clean_items(?) || '%'", params[:term].to_s)
      results = results.where(machine_type: Array(params[:machine_type])) if params[:machine_type].present?
      results = results.where(manufacturer: Array(params[:manufacturer])) if params[:manufacturer].present?
      results = results.where("year >= ?", params[:by_machine_year_gte].to_i) if params[:by_machine_year_gte].present?
      results = results.where("year <= ?", params[:by_machine_year_lte].to_i) if params[:by_machine_year_lte].present?
      results = results.to_a

      sort = Machine::SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "alphabetical"
      life_list_machine_ids = current_user ? UserMachineXref.where(user_id: current_user.id, machine_id: results.map(&:id)).pluck(:machine_id).to_set : Set.new
      results = results.sort_by { |m| Machine.sort_key(m, sort, life_list_machine_ids) }
                       .map { |m| { label: m.name_and_year, value: m.name_and_year, id: m.id, group_id: m.machine_group_id, ic_eligible: m.ic_eligible } }
    else
      sql = <<-SQL
      select distinct m.name, m."year", m.id, m.machine_group_id, m.manufacturer from locations l
      inner join location_machine_xrefs lmx on lmx.location_id = l.id
      inner join machines m on m.id = lmx.machine_id
      where region_id = 1 and (clean_items(m.name)) ilike '%' || clean_items(:term) || '%'
      order by m.name
      SQL

      sanitized_sql = ActiveRecord::Base.sanitize_sql_array([ sql, { term: params[:term] } ])

      results = ActiveRecord::Base.connection.select_all(sanitized_sql)
                                  .map do |m|
        name_year = "#{m['name']} (#{m['manufacturer']}, #{m['year']})"

        { label: name_year, value: name_year, id: m["id"], group_id: m["machine_group_id"] }
      end

    end

    render json: results
  end

  def manufacturers
    list = Rails.cache.fetch("manufacturers_list", expires_in: 1.hour) do
      Machine.distinct.pluck(:manufacturer).compact.sort
    end
    render json: list.map { |m| { id: m, text: m } }
  end
end
