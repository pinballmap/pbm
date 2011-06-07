require 'spec_helper'

describe Location do
  before(:each) do
    @l = Factory.create(:location)
    @m1 = Factory.create(:machine, :name => 'Sassy')
    @m2 = Factory.create(:machine, :name => 'Cleo')
    @lmx1 = Factory.create(:location_machine_xref, :location => @l, :machine => @m1)
    @lmx2 = Factory.create(:location_machine_xref, :location => @l, :machine => @m2)
  end

#  describe '#after_save' do
#    it 'should try to find the latitude and longitude of the location after it creates it' do
#      @l.lat.should == 45.520784
#      @l.lon.should == -122.66275
#    end
#  end

  describe '#location_machine_xrefs' do
    it 'should return all machines for this location' do
      @l.location_machine_xrefs.should == [@lmx1, @lmx2]
    end
  end

  describe '#machine_names' do
    it 'should return all machine names for this location' do
      @l.machine_names.should == ['Cleo', 'Sassy']
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      l = Factory.create(:location)
      ['Foo', 'Bar', 'Baz', "Beans'"].each {|name| Factory.create(:location_machine_xref, :location => l, :machine => Factory.create(:machine, :name => name)) }

      l.content_for_infowindow.chomp.should == "'<div class=\"infowindow\">Test Location Name<br />303 Southeast 3rd Avenue<br />Portland, OR, 97214<br /><br /><hr /><br />Bar<br />Baz<br />Beans\\'<br />Foo<br /></div>'"
    end
  end
end
