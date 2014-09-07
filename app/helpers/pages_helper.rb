module PagesHelper
  def other_regions_html(region)
    html = Region.where('id != ?', region.id).order('name').map { |other_region| "<li><a href='/#{other_region.name.downcase}'>#{other_region.full_name}</a></li>" }.join

    html.html_safe
  end
end
