module PagesHelper
  def other_regions_html(region)
    html = Region.where('id != ?', region.id).order('name').map { |other_region| "<li><a href='/#{other_region.name.downcase}'>#{other_region.full_name}</a></li>" }.join

    html.html_safe
  end

  def title_for_path(path, region = nil)
    title = region.nil? ? title_for_regionless_path(path) : title_for_region_path(path, region)
    title
  end

  def title_for_region_path(path, region)
    title = ''
    if path == suggest_path(region.name)
      title = 'Suggest a New Location to the '
    elsif path == about_path(region.name)
      title = 'About the '
    elsif path == events_path(region.name)
      title = 'Upcoming Events - '
    elsif path == high_rollers_path(region.name)
      title = 'High Scores - '
    end

    title += "#{region.full_name} Pinball Map"
    title
  end

  def title_for_regionless_path(path)
    title = ''

    if path == app_path
      title = 'App - '
    elsif path == app_support_path
      title = 'App Support - '
    elsif path == faq_path
      title = 'FAQ - '
    elsif path == store_path
      title = 'Store - T-Shirts for Sale! - '
    elsif path == donate_path
      title = 'Donate - '
    elsif path =~ /profile/
      title = 'User Profile - '
    elsif path =~ /login/
      title = 'Login - '
    elsif path =~ /join/
      title = 'Join - '
    elsif path =~ /password/
      title = 'Forgot Password - '
    elsif path =~ /confirmation/
      title = 'Confirmation Instructions - '
    else
      title = ''
    end

    title += 'Pinball Map'
    title
  end
end
