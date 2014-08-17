require 'spec_helper'

describe Location do
  before(:each) do
    @l = FactoryGirl.create(:location)
    @m1 = FactoryGirl.create(:machine, :name => 'Sassy')
    @m2 = FactoryGirl.create(:machine, :name => 'Cleo')
    @lmx1 = FactoryGirl.create(:location_machine_xref, :location => @l, :machine => @m1, :created_at => '2014-01-15 04:00:00')
    @lmx2 = FactoryGirl.create(:location_machine_xref, :location => @l, :machine => @m2, :created_at => '2014-01-15 05:00:00')
  end

#  describe '#after_save' do
#    it 'should try to find the latitude and longitude of the location after it creates it' do
#      expect(@l.lat).to eq(45.520784)
#      expect(@l.lon).to eq(-122.66275)
#    end
#  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      FactoryGirl.create(:event, :location => @l)
      FactoryGirl.create(:location_picture_xref, :location => @l, :photo => nil)

      @l.destroy

      expect(Event.all).to eq([])
      expect(LocationPictureXref.all).to eq([])
      expect(LocationMachineXref.all).to eq([])
      expect(MachineScoreXref.all).to eq([])
      expect(Location.all).to eq([])
    end
  end

  describe 'website validation' do
    it 'should allow blank websites' do
      @l.update_attributes(:website => '')
      expect(lambda do
        @l.save!
      end).to_not raise_error
    end
    it 'should not update location with websites that do not start with http://' do
      @l.update_attributes(:website => 'lol.com')
      expect(lambda do
        @l.save!
      end).to raise_error

      @l.update_attributes(:website => 'http://lol.com')
      expect(lambda do
        @l.save!
      end).to_not raise_error
    end
  end

  describe '#location_machine_xrefs' do
    it 'should return all machines for this location' do
      expect(@l.location_machine_xrefs.order(:id)).to eq([@lmx1, @lmx2])
    end
  end

  describe '#machine_names' do
    it 'should return all machine names for this location' do
      expect(@l.machine_names).to eq(['Cleo', 'Sassy'])
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      l = FactoryGirl.create(:location)
      ['Foo', 'Bar', 'Baz', "Beans'"].each {|name| FactoryGirl.create(:location_machine_xref, :location => l, :machine => FactoryGirl.create(:machine, :name => name)) }

      expect(l.content_for_infowindow.chomp).to eq("'<div class=\"infowindow\" id=\"infowindow_#{l.id}\"><div class=\"gm_location_name\">Test Location Name</div><div class=\"gm_address\">303 Southeast 3rd Avenue<br />Portland, OR, 97214<br /></div><hr /><div class=\"gm_machines\" id=\"gm_machines_#{l.id}\">Bar<br />Baz<br />Beans\\'<br />Foo<br /></div></div>'")
    end
  end

  describe '#newest_machine_xref' do
    it 'should return the latest machine that has been added' do
      expect(@l.newest_machine_xref).to eq(@lmx2)
    end
  end
end
