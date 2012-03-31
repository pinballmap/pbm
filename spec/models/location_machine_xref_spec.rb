require 'spec_helper'

describe LocationMachineXref do
  before(:each) do
    @l = Factory.create(:location)
    @m = Factory.create(:machine, :name => 'Sassy')
    @lmx = Factory.create(:location_machine_xref, :location => @l, :machine => @m)
  end

  describe '#update_condition' do
    it 'should update the condition of the lmx, timestamp it, and email the admins of the region' do
      @lmx.update_condition('foo')

      @lmx.condition.should == 'foo'
      @lmx.condition_date.to_s.should == Time.now.to_s
    end
  end
end
