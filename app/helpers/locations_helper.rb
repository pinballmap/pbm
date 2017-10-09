module LocationsHelper
  def banner(type, header_text, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggleData('#{type}'#{", #{obj.id}" if obj});">
    <span>#{header_text}</span>
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
