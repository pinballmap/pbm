require 'spec_helper'

describe LocationsHelper, type: :helper do

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
