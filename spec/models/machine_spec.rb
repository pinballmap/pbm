require 'spec_helper'

describe Machine do
  before(:each) do
    @machine_group = FactoryGirl.create(:machine_group)
    @l = FactoryGirl.create(:location)
    @m = FactoryGirl.create(:machine, name: 'Sassy', machine_group: @machine_group)
    @lmx = FactoryGirl.create(:location_machine_xref, location: @l, machine: @m)
    @msx = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx)
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      @m.destroy

      expect(Machine.all).to eq([])
      expect(LocationMachineXref.all).to eq([])
      expect(MachineScoreXref.all).to eq([])
    end
  end

  describe '#all_machines_in_machine_group' do
    it 'should return this machine and all machines group together with it' do
      sassy_champ = FactoryGirl.create(:machine, name: 'Sassy Championship Edition', machine_group: @machine_group)

      expect(@m.all_machines_in_machine_group).to include(@m, sassy_champ)
    end
  end
end
