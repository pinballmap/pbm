module NavigationHelpers
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    when /the index of locations/
      locations_path

    when /new location/
      new_location_path

    when /^(.*)'s detail page$/i
      location_path(Location.find_by_name($1))

    when /^(.*)'s edit page$/i
      edit_location_path(Location.find_by_name($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
