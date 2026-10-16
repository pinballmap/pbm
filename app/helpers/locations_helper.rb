module LocationsHelper
  def banner(type, header_text, icon, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggleData('#{type}'#{", #{obj.id}" if obj});">
  #{icon}<span>#{header_text}</span>
  </div>
HERE
    html.html_safe
  end

  def quick_buttons(type, icon, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggle_machine_data('#{type}'#{", #{obj.id}" if obj});">
  #{icon}
  </div>
HERE
    html.html_safe
  end

  def event_date_range(event)
    start_date = event.start_date
    end_date = event.end_date
    return unless start_date
    return start_date.strftime("%a, %b %-d, %Y") if end_date.nil? || end_date == start_date

    "#{start_date.strftime('%a, %b %-d')} - #{end_date.strftime('%a, %b %-d, %Y')}"
  end

  def search_banner(type, header_text)
    html = <<HERE
  <div id="#{type}_banner" class="search_banner">
    <span>#{header_text}</span>
  </div>
HERE
    html.html_safe
  end
end
