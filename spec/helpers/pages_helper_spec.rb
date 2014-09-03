require 'spec_helper'

describe PagesHelper, type: :helper do
  describe '#other_regions_html' do
    it 'should give me html of links to other regions landing pages' do
      r = FactoryGirl.create(:region)
      FactoryGirl.create(:region, name: 'Xanadu', full_name: 'Xanadu, FL')
      FactoryGirl.create(:region, name: 'Anaconda', full_name: 'Anaconda, MI')

      expect(helper.other_regions_html(r)).to eq("<li><a href='/anaconda'>Anaconda, MI</a></li><li><a href='/xanadu'>Xanadu, FL</a></li>")
    end
  end
end
