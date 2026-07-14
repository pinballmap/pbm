module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.merge(sort: column, direction: direction, page: nil), class: css_class
  end

  def machine_select_options(selected_ids = [])
    Machine.select_option_data(selected_ids)
  end
end
