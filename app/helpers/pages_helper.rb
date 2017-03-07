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

  def desc_for_path(path, region = nil)
    desc = region.nil? ? desc_for_regionless_path(path) : desc_for_region_path(path, region)
    desc
  end

  def desc_for_region_path(path, region)
    desc = ''
    if path == suggest_path(region.name)
      desc = "Add a new location to the #{region.full_name} Pinball Map! This crowdsourced map relies on your knowledge and help!"
    elsif path == about_path(region.name)
      desc = "Contact the administrator of the #{region.full_name} Pinball Map. Suggest a new region. Check out the most popular pinball machines on the map!"
    elsif path == events_path(region.name)
      desc = "Upcoming pinball events in #{region.full_name}. Tournaments, leagues, charities, launch parties, and more!"
    elsif path == high_rollers_path(region.name)
      desc = "High scores for the #{region.full_name} Pinball Map! If you get a high score on a pinball machine, add it to the map!"
    else
      desc = "Find local places to play pinball! The #{region.full_name} Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area."
    end

    desc
  end

  def desc_for_regionless_path(path)
    desc = ''

    if path == app_path
      desc = "Pinball Map App for iOS and Android. Find pinball machines to play near you! Update the app like the true champ you are."
    elsif path == app_support_path
      desc = 'Pinball Map iOS screenshots, support, and FAQ'
    elsif path == faq_path
      desc = 'Pinball Map Frequently Asked Questions (FAQ). Got a question? It may be answered here.'
    elsif path == store_path
      desc = "Pinball Map Store! We have a t-shirt for sale. Get it while it's hot (pink)."
    elsif path == donate_path
      desc = "Donate to Pinball Map. Donations help us manage the costs of running the site. Thank you!"
    elsif path =~ /profile/
      desc = "The user profile tracks your Pinball Map contributions. It's a concise overview of your edits, high scores, and favorite locations."
    elsif path =~ /login/
      desc = 'Log in to Pinball Map and help keep it up to date!'
    elsif path =~ /join/
      desc = "Join Pinball Map and help keep your local pinball map up to date! This site relies on user contributions. Joining is quick and easy!"
    elsif path =~ /password/
      desc = 'If you forgot your Pinball Map password, you can recover it from here.'
    elsif path =~ /confirmation/
      desc = "The email confirmation can be resent from this page."
    else
      desc = "The Pinball Map website and free mobile app will help you places to play pinball! Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area."
    end

    desc
  end
end
