require 'spec_helper'

describe LocationsHelper do
  describe '#open_closed_arrows' do
    it 'should give me some open and closed arrows' do
      l = Factory.create(:location)
      helper.open_closed_arrows_for('foo', l.id).should == "<div id='foo_open_arrow_#{l.id}' class='float_left' style='display: none;'><img alt='open arrow' src='images/open_arrow.gif' /></div><div id='foo_closed_arrow_#{l.id}' class='float_left'><img alt='closed arrow' src='images/closed_arrow.gif' /></div>"
    end
  end

  describe '#banner' do
    it 'should give me a banner' do
      l = Factory.create(:location)
      helper.banner(l, 'cool_type', 'This is a cool type, bro').should == <<HERE
<div id="cool_type_banner_#{l.id}" class="sub_nav_item" onclick="toggle_data('cool_type', #{l.id});">
  <span>This is a cool type, bro</span>
  #{open_closed_arrows_for('cool_type', l.id)}
</div>
HERE
    end
  end
end
