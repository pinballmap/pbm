require 'spec_helper'

describe Location do
  before(:each) do
    @l = Factory.create(:location)
    @m1 = Factory.create(:machine, :name => 'Sassy')
    @m2 = Factory.create(:machine, :name => 'Cleo')
    @lmx1 = Factory.create(:location_machine_xref, :location => @l, :machine => @m1)
    @lmx2 = Factory.create(:location_machine_xref, :location => @l, :machine => @m2)
  end

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
end
