require 'spec_helper'

describe Machine do
  before(:each) do
    @l = Factory.create(:location)
    @m = Factory.create(:machine, :name => 'Sassy')
    @lmx = Factory.create(:location_machine_xref, :location => @l, :machine => @m)
    @msx = Factory.create(:machine_score_xref, :location_machine_xref => @lmx)
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      @m.destroy

      Machine.all.should == []
      LocationMachineXref.all.should == []
      MachineScoreXref.all.should == []
    end
  end
end
