require 'spec_helper'

describe LocationsHelper do
  describe '#locations_javascript_data' do
    it 'should build up a list of location information to put out to the map' do
      locations = Array.new
      2.times do
        l = Factory.create(:location)
        ['Foo', 'Bar', 'Baz'].each {|name| Factory.create(:location_machine_xref, :location => l, :machine => Factory.create(:machine, :name => name)) }
        locations << l
      end

      helper.locations_javascript_data(locations).should == [
        [ locations[0].id,  locations[1].id  ],
        [ locations[0].lat, locations[1].lat ],
        [ locations[0].lon, locations[1].lon ],
        [ 
          "'<div class=\"infowindow\">Test Location Name<br />123 Pine<br />Portland, OR, 97211<br /><hr /><br />Foo<br />Bar<br />Baz<br /></div>'",
          "'<div class=\"infowindow\">Test Location Name<br />123 Pine<br />Portland, OR, 97211<br /><hr /><br />Foo<br />Bar<br />Baz<br /></div>'"
        ],
      ]
    end
  end

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
