module PagesHelper
  def other_regions_html(region)
    html = Region.where('id != ?', region.id).order('name').collect {|other_region| "<li><a href='/#{other_region.name.downcase}'>#{other_region.full_name}</a></li><div class='clear'></div>"}
    html.join.html_safe
  end
end
