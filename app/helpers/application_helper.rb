module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, params.merge(sort: column, direction: direction, page: nil), class: css_class
  end
  def contributor_rank_icon(user)
    image_tag("rank/Rank_#{user.contributor_rank_int}.png", :class => "profile_rank_icon")
  end
end
