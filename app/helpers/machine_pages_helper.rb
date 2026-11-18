module MachinePagesHelper
  def machine_page_machine(params)
    return nil if @region

    # The map JS sends ungrouped machines as by_machine_single_id, which shows the same results
    key = %i[by_machine_id by_machine_single_id].find { |k| params[k].present? }
    return nil unless key

    ids = Array(params[key]).compact_blank
    return nil unless ids.size == 1
    return nil if (MapsController::MAP_FILTER_PARAMS + [ :by_machine_year ] - [ key ]).any? { |k| params[k].present? }

    machine = Machine.find_by(id: ids.first)
    return nil if machine.nil? || (key == :by_machine_single_id && machine.machine_group_id)

    machine
  end

  def machine_page_title(machine)
    "#{machine_page_name(machine)} - Where to Play - Pinball Map"
  end

  def machine_page_canonical_id(machine)
    machine.machine_group_id ? Machine.where(machine_group_id: machine.machine_group_id).minimum(:id) : machine.id
  end

  def machine_page_description(machine)
    machines = machine.all_machines_in_machine_group.sort_by(&:id)
    name = machine_page_name(machine)
    oldest = machines.min_by { |m| m.year || Float::INFINITY }
    location_count = LocationMachineXref.where(machine_id: machines.map(&:id)).distinct.count(:location_id)

    desc = "Where to play #{name}#{oldest.year_and_manufacturer} pinball. "
    desc += location_count.zero? ? "It isn't currently listed at any locations on Pinball Map." : "Pinball Map lists it at #{number_with_delimiter(location_count)} #{'location'.pluralize(location_count)}."
    if machines.size > 1
      versions = machines.map { |m| m.name.start_with?(name) ? m.name.delete_prefix(name).strip.delete_prefix("(").delete_suffix(")") : m.name }
      desc += " Versions: #{versions.compact_blank.join(', ')}."
    end
    desc
  end

  private

  def machine_page_name(machine)
    machine.machine_group&.name || machine.name
  end
end
