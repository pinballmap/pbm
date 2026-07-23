class FilterSummary
  MAX_CATEGORIES = 3

  MACHINE_PARAM_FAMILIES = %i[
    by_machine_id by_machine_single_id by_machine_id_ic by_machine_single_id_ic
    by_opdb_id by_ipdb_id by_machine_group_id
  ].freeze

  IC_FAMILIES = %i[by_machine_id_ic by_machine_single_id_ic].freeze

  MAX_MACHINE_NAMES = 5

  MACHINE_TYPE_LABELS = { "em" => "EM", "me" => "EM", "ss" => "SS" }.freeze

  AT_LEAST_N_MACHINES_KEYS = %i[
    by_at_least_n_machines by_at_least_n_machines_city
    by_at_least_n_machines_zone by_at_least_n_machines_type by_at_least_n_machines_name
  ].freeze

  def initialize(params)
    @params = params
  end

  def to_s
    fragments = category_fragments
    return nil if fragments.empty?
    return "multiple filters" if fragments.size > MAX_CATEGORIES

    fragments.to_sentence(two_words_connector: " and ", last_word_connector: ", and ")
  end

  private

  def category_fragments
    [
      machine_fragment,
      location_type_fragment,
      manufacturer_fragment,
      machine_type_fragment,
      year_range_fragment,
      at_least_n_machines_fragment,
      stern_army_fragment,
      ic_active_fragment,
      operator_fragment,
      zone_fragment,
      geography_fragment
    ].compact
  end

  def values_for(key)
    Array(@params[key]).reject(&:blank?)
  end

  def to_sentence_or(values)
    values.to_sentence(two_words_connector: " or ", last_word_connector: ", or ")
  end

  # Machine identity (by_machine_id, by_opdb_id, etc.) resolves to a specific machine or
  # group name. Only one family can be active at a time -- the map's machine picker never
  # submits more than one -- so ambiguous combinations are treated as no filter at all.
  def machine_fragment
    families = MACHINE_PARAM_FAMILIES.select { |family| values_for(family).any? }
    return nil if families.size != 1

    family = families.first
    names = machine_names_for(family)
    return nil if names.empty?

    text = names.size > MAX_MACHINE_NAMES ? "multiple machines" : to_sentence_or(names)
    IC_FAMILIES.include?(family) ? "#{text} with Insider Connected active" : text
  end

  def machine_names_for(family)
    ids = values_for(family)

    case family
    when :by_machine_group_id
      MachineGroup.where(id: ids.map(&:to_i)).distinct.pluck(:name)
    when :by_machine_id, :by_machine_id_ic
      machines = Machine.where(id: ids.map(&:to_i))
      group_names = machines.where.not(machine_group_id: nil).joins(:machine_group).distinct.pluck("machine_groups.name")
      single_names = machines.where(machine_group_id: nil).pluck(:name)
      (group_names + single_names).uniq
    when :by_machine_single_id, :by_machine_single_id_ic
      Machine.where(id: ids.map(&:to_i)).distinct.pluck(:name)
    when :by_opdb_id
      Machine.where(opdb_id: ids).distinct.pluck(:name)
    when :by_ipdb_id
      Machine.where(ipdb_id: ids.map(&:to_i)).distinct.pluck(:name)
    end
  end

  def location_type_fragment
    ids = values_for(:by_type_id)
    return nil if ids.empty?

    names = LocationType.where(id: ids.map(&:to_i)).distinct.pluck(:name)
    return nil if names.empty?

    "location type #{to_sentence_or(names)}"
  end

  def manufacturer_fragment
    names = values_for(:manufacturer)
    return nil if names.empty?

    "machines manufactured by #{to_sentence_or(names)}"
  end

  def machine_type_fragment
    values = values_for(:by_machine_type)
    return nil if values.empty?

    labels = values.map { |v| MACHINE_TYPE_LABELS[v] || v.upcase }.uniq
    "#{to_sentence_or(labels)} machines"
  end

  def year_range_fragment
    gte = @params[:by_machine_year_gte].presence
    lte = @params[:by_machine_year_lte].presence
    return nil if gte.blank? && lte.blank?

    if gte.present? && lte.present?
      "a machine made between #{gte} and #{lte}"
    elsif gte.present?
      "a machine made in #{gte} or later"
    else
      "a machine made in #{lte} or earlier"
    end
  end

  def at_least_n_machines_fragment
    key = AT_LEAST_N_MACHINES_KEYS.find { |k| @params[k].present? }
    return nil unless key

    "at least #{@params[key]} machines"
  end

  def stern_army_fragment
    "Stern Army" if @params[:by_is_stern_army].present?
  end

  def ic_active_fragment
    return nil if @params[:by_ic_active].blank?
    return nil if IC_FAMILIES.any? { |family| values_for(family).any? }

    "at least one Stern Insider Connected machine"
  end

  def operator_fragment
    ids = values_for(:by_operator_id)
    return nil if ids.empty?

    names = Operator.where(id: ids.map(&:to_i)).distinct.pluck(:name)
    return nil if names.empty?

    "operator #{to_sentence_or(names)}"
  end

  def zone_fragment
    ids = values_for(:by_zone_id)
    return nil if ids.empty?

    names = Zone.where(id: ids.map(&:to_i)).distinct.pluck(:name)
    return nil if names.empty?

    "zone #{to_sentence_or(names)}"
  end

  def geography_fragment
    states = values_for(:by_state_name).presence || values_for(:by_state_id)
    countries = values_for(:by_country)
    return nil if states.blank? && countries.blank?

    parts = [ states, countries ].select(&:present?).map { |values| to_sentence_or(values) }
    "in #{parts.join(', ')}"
  end
end
