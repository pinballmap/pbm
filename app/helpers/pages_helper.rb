module PagesHelper
  def other_regions_html(region)
    html = Region.where('id != ?', region.id).order('name').map { |other_region| "<li><a href='/#{other_region.name.downcase}'>#{other_region.full_name}</a></li>" }.join

    html.html_safe
  end

  def title_for_path(path, region = nil)
    title = ''

    if region.nil?
      if path == apps_path || path == apps_support_path
        title = 'App'
      elsif path == faq_path
        title = 'FAQ'
      elsif path == store_path
        title = 'Store - T-Shirts for Sale!'
      elsif path == donate_path
        title = 'Donate'
      elsif path =~ /profile/
        title = 'User Profile'
      else
        title = 'Pinball Map'
      end
    else
      if path == suggest_path(@region.name)
        title = 'Suggest a New Location to the '
      elsif path == about_path(@region.name)
        title = 'About the '
      elsif path == events_path(@region.name)
        title = 'Upcoming Events - '
      elsif path == high_rollers_path(@region.name)
        title = 'High Scores - '
      end

      title += "#{region.full_name} Pinball Map"
    end

    title
  end
end
