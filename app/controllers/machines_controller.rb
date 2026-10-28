class MachinesController < ApplicationController
  def opdb_img
    machine = Machine.select(:opdb_img, :ic_eligible).find(params[:id])
    json = { opdb_img: machine.opdb_img.presence, ic_eligible: machine.ic_eligible }
    json[:already_at_location] = LocationMachineXref.exists?(location_id: params[:location_id], machine_id: params[:id]) if params[:location_id].present?
    render json: json
  end

  def autocomplete
    if params[:region_level_search].nil? || @region.nil?
      results = Machine.matching_words(:name, params[:term])
      results = results.where(machine_type: Array(params[:machine_type])) if params[:machine_type].present?
      results = results.where(manufacturer: Array(params[:manufacturer])) if params[:manufacturer].present?
      results = results.where("year >= ?", params[:by_machine_year_gte].to_i) if params[:by_machine_year_gte].present?
      results = results.where("year <= ?", params[:by_machine_year_lte].to_i) if params[:by_machine_year_lte].present?
      results = results.to_a

      sort = Machine::SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "alphabetical"
      life_list_machine_ids = current_user ? UserMachineXref.where(user_id: current_user.id, machine_id: results.map(&:id)).pluck(:machine_id).to_set : Set.new
      results = results.sort_by { |m| Machine.sort_key(m, sort, life_list_machine_ids) }
                       .map { |m| { label: m.name_and_year, value: m.name_and_year, id: m.id, group_id: m.machine_group_id, ic_eligible: m.ic_eligible, in_life_list: life_list_machine_ids.include?(m.id) } }
    else
      region_machine_ids = LocationMachineXref.joins(:location).where(locations: { region_id: @region.id }).select(:machine_id)

      results = Machine.where(id: region_machine_ids)
                       .matching_words(:name, params[:term])
                       .order(:name)
                       .map do |m|
        name_year = "#{m.name} (#{m.manufacturer}, #{m.year})"

        { label: name_year, value: name_year, id: m.id, group_id: m.machine_group_id }
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

  def years
    years = Rails.cache.fetch("machine_years", expires_in: 1.day) do
      Machine.distinct.pluck(:year).compact.sort
    end
    render json: years
  end
end
