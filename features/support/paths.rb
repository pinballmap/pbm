module NavigationHelpers
  def path_to(page_name)
    case page_name

    when /"(.*)"'s events page/
      "/#{$1.downcase}/events"

    when /"(.*)"'s home page/
      "/#{$1.downcase}"

    when /"(.*)"'s suggest new location page/
      "/#{$1.downcase}/suggest_new_location"

    when /"(.*)"'s links page/
      "/#{$1.downcase}/links"

    when /"(.*)"'s high rollers page/
      "/#{$1.downcase}/high_rollers"

    when /"(.*)"'s contact page/
      "/#{$1.downcase}/contact"

    when /the home\s?page/
      '/'

    when /^the location detail page for "(.*)"$/i
      location_path(Location.find_by_name($1))

    when /^the location edit page for "(.*)"$/i
      edit_location_path(Location.find_by_name($1))

    when /^the machine detail page for "(.*)"$/i
      machine_path(Machine.find_by_name($1))

    when /^the machine edit page for "(.*)"$/i
      edit_machine_path(Machine.find_by_name($1))

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
