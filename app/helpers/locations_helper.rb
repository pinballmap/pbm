module LocationsHelper
  def open_closed_arrows_for(name, id=nil)
    arrows = "<div id='#{name}_open_arrow#{"_#{id}" if (id)}' class='float_left' style='display: none;'><img alt='open arrow' src='images/open_arrow.gif' /></div>"
    arrows += "<div id='#{name}_closed_arrow#{"_#{id}" if (id)}' class='float_left'><img alt='closed arrow' src='images/closed_arrow.gif' /></div>"

    arrows.html_safe
  end

  def banner(obj=nil, type, header_text)
    html = <<HERE
<div id="#{type}_banner#{"_#{obj.id}" if (obj)}" class="sub_nav_item" onclick="toggle_data('#{type}'#{", #{obj.id}" if (obj)});">
  <span>#{header_text}</span>
  #{open_closed_arrows_for(type, obj ? obj.id : nil)}
</div>
HERE
    html.html_safe
  end

  def search_banner(type, header_text)
    html = <<HERE
<div id="#{type}_banner" class="sub_nav_item" onclick="hide_search_sections(); toggle_data('#{type}');">
  <span>#{header_text}</span>
  #{open_closed_arrows_for(type)}
</div>
HERE
    html.html_safe
  end
end
