class MachinesController < ApplicationController
  def autocomplete
    if params[:region_level_search].nil?
      results = Machine.where("clean_items(name) ilike '%' || clean_items(?) || '%'", params[:term])
                       .sort_by(&:name)
                       .map { |m| { label: m.name_and_year, value: m.name_and_year, id: m.id, group_id: m.machine_group_id } }
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
end
