require 'spec_helper'

describe PagesHelper do
  describe '#other_regions_html' do
    it 'should give me html of links to other regions landing pages' do
      r = Factory.create(:region)
      other_region = Factory.create(:region, :name => 'Xanadu')
      yet_another_region = Factory.create(:region, :name => 'Anaconda')

      helper.other_regions_html(r).should == "<li><a href='/anaconda'>Anaconda</a></li><div class='clear'></div><li><a href='/xanadu'>Xanadu</a></li><div class='clear'></div>"
    end
  end
end
