require 'spec_helper'

describe Location do
  before(:each) do
    @l = FactoryGirl.create(:location)
    @m1 = FactoryGirl.create(:machine, :name => 'Sassy')
    @m2 = FactoryGirl.create(:machine, :name => 'Cleo')
    @lmx1 = FactoryGirl.create(:location_machine_xref, :location => @l, :machine => @m1)
    @lmx2 = FactoryGirl.create(:location_machine_xref, :location => @l, :machine => @m2)
  end

#  describe '#after_save' do
#    it 'should try to find the latitude and longitude of the location after it creates it' do
#      @l.lat.should == 45.520784
#      @l.lon.should == -122.66275
#    end
#  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      FactoryGirl.create(:event, :location => @l)
      FactoryGirl.create(:location_picture_xref, :location => @l, :photo => nil)

      @l.destroy

      Event.all.should == []
      LocationPictureXref.all.should == []
      LocationMachineXref.all.should == []
      MachineScoreXref.all.should == []
      Location.all.should == []
    end
  end

  describe 'website validation' do
    it 'should allow blank websites' do
      @l.update_attributes(:website => '')
      lambda do
        @l.save!
      end.should_not raise_error
    end
    it 'should not update location with websites that do not start with http://' do
      @l.update_attributes(:website => 'lol.com')
      lambda do
        @l.save!
      end.should raise_error

      @l.update_attributes(:website => 'http://lol.com')
      lambda do
        @l.save!
      end.should_not raise_error
    end
  end

  describe '#location_machine_xrefs' do
    it 'should return all machines for this location' do
      @l.location_machine_xrefs.should == [@lmx2, @lmx1]
    end
  end

  describe '#machine_names' do
    it 'should return all machine names for this location' do
      @l.machine_names.should == ['Cleo', 'Sassy']
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      l = FactoryGirl.create(:location)
      ['Foo', 'Bar', 'Baz', "Beans'"].each {|name| FactoryGirl.create(:location_machine_xref, :location => l, :machine => FactoryGirl.create(:machine, :name => name)) }

      l.content_for_infowindow.chomp.should == "'<div class=\"infowindow\"><div class=\"gm_location_name\">Test Location Name</div><div class=\"gm_address\">303 Southeast 3rd Avenue<br />Portland, OR, 97214<br /></div><hr /><div class=\"gm_machines\">Bar<br />Baz<br />Beans\\'<br />Foo<br /></div></div>'"
    end
  end
end
