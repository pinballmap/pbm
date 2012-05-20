require 'spec_helper'

describe PagesHelper do
  describe '#other_regions_html' do
    it 'should give me html of links to other regions landing pages' do
      r = FactoryGirl.create(:region)
      other_region = FactoryGirl.create(:region, :name => 'Xanadu', :full_name => 'Xanadu, FL')
      yet_another_region = FactoryGirl.create(:region, :name => 'Anaconda', :full_name => 'Anaconda, MI')

      helper.other_regions_html(r).should == "<li><a href='/anaconda'>Anaconda, MI</a></li><div class='clear'></div><li><a href='/xanadu'>Xanadu, FL</a></li><div class='clear'></div>"
    end
  end
end
