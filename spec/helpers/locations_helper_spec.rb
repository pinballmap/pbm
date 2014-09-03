require 'spec_helper'

describe LocationsHelper, type: :helper do
  describe '#open_closed_arrows' do
    it 'should give me some open and closed arrows' do
      l = FactoryGirl.create(:location)
      expect(helper.open_closed_arrows_for('foo', l.id)).to eq("<div class='arrow' id='foo_open_arrow_#{l.id}' style='display: none;'><img alt='open arrow' src='/assets/open_arrow.gif' /></div><div class='arrow' id='foo_closed_arrow_#{l.id}'><img alt='closed arrow' src='/assets/closed_arrow.gif' /></div>")

      expect(helper.open_closed_arrows_for('foo')).to eq("<div class='arrow' id='foo_open_arrow' style='display: none;'><img alt='open arrow' src='/assets/open_arrow.gif' /></div><div class='arrow' id='foo_closed_arrow'><img alt='closed arrow' src='/assets/closed_arrow.gif' /></div>")
    end
  end

  describe '#banner' do
    it 'should give me a banner' do
      l = FactoryGirl.create(:location)

      expect(helper.banner('cool_type', 'This is a cool type, bro', l)).to eq(<<HERE)
<div id="cool_type_banner_#{l.id}" class="sub_nav_item cool_type_toggle" onclick="toggleData('cool_type', #{l.id});">
  <span>This is a cool type, bro</span>
  <div class='arrow' id='cool_type_open_arrow_2' style='display: none;'><img alt='open arrow' src='/assets/open_arrow.gif' /></div><div class='arrow' id='cool_type_closed_arrow_2'><img alt='closed arrow' src='/assets/closed_arrow.gif' /></div>
</div>
HERE

      expect(helper.banner('cool_type', 'This is a cool type, bro')).to eq(<<HERE)
<div id="cool_type_banner" class="sub_nav_item cool_type_toggle" onclick="toggleData('cool_type');">
  <span>This is a cool type, bro</span>
  <div class='arrow' id='cool_type_open_arrow' style='display: none;'><img alt='open arrow' src='/assets/open_arrow.gif' /></div><div class='arrow' id='cool_type_closed_arrow'><img alt='closed arrow' src='/assets/closed_arrow.gif' /></div>
</div>
HERE
    end
  end

  describe '#search_banner' do
    it 'should give me a banner' do
      FactoryGirl.create(:location)
      expect(helper.search_banner('by_cool_type', 'This is a cool type, bro')).to eq(<<HERE)
<div id="by_cool_type_banner" class="search_banner">
  <span>This is a cool type, bro</span>
</div>
HERE
    end
  end
end
