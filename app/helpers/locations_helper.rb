module LocationsHelper
  def open_closed_arrows_for(name, id = nil)
    arrows = "<div class='arrow' id='#{name}_open_arrow#{"_#{id}" if id}' style='display: none;'><img alt='open arrow' src='#{asset_path 'open_arrow.gif'}' /></div>"
    arrows += "<div class='arrow' id='#{name}_closed_arrow#{"_#{id}" if id}'><img alt='closed arrow' src='#{asset_path 'closed_arrow.gif'}' /></div>"

    arrows.html_safe
  end

  def banner(type, header_text, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggleData('#{type}'#{", #{obj.id}" if obj});">
    <span>#{header_text}</span>
    #{open_closed_arrows_for(type, obj ? obj.id : nil)}
  </div>
HERE
    html.html_safe
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
