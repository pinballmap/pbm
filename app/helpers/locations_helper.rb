module LocationsHelper
  def open_closed_arrows_for(name, id)
    arrows = "<div id='#{name}_open_arrow_#{id}' class='float_left' style='display: none;'><img alt='open arrow' src='images/open_arrow.gif' /></div>"
    arrows += "<div id='#{name}_closed_arrow_#{id}' class='float_left'><img alt='closed arrow' src='images/closed_arrow.gif' /></div>"

    arrows.html_safe
  end
end
