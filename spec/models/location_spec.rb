require 'spec_helper'

describe Location do
  describe 'scopes' do
    before(:each) do
      @l = Factory.create(:location, :name => 'test location')
      @m1 = Factory.create(:machine, :name => 'test machine')
      @m2 = Factory.create(:machine, :name => 'test machine')
      @lmx1 = Factory.create(:location_machine_xref, :location_id => @l.id, :machine_id => @m1.id)
      @lmx2 = Factory.create(:location_machine_xref, :location_id => @l.id, :machine_id => @m2.id)
    end

    describe 'machines' do
      it 'should return all machines for this location' do
        @l.location_machine_xrefs.should == [@lmx1, @lmx2]
      end
    end
  end
end
