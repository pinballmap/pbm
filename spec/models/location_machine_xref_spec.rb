require 'spec_helper'

describe LocationMachineXref do
  before(:each) do
    @r = FactoryGirl.create(:region, name: 'Portland', should_email_machine_removal: 1)
    @r_no_email = FactoryGirl.create(:region, should_email_machine_removal: 0)

    @u = FactoryGirl.create(:user, region: @r, email: 'foo@bar.com')

    @l = FactoryGirl.create(:location, region: @r, name: 'Cool Bar')
    @l_no_email = FactoryGirl.create(:location, region: @r_no_email)

    @m = FactoryGirl.create(:machine, name: 'Sassy')

    @lmx = FactoryGirl.create(:location_machine_xref, location: @l, machine: @m)
    @lmx_no_email = FactoryGirl.create(:location_machine_xref, location: @l_no_email, machine: @m)
  end

  describe '#update_condition' do
    it 'should update the condition of the lmx, timestamp it, and email the admins of the region' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "foo\nSassy\nCool Bar\nPortland\n(entered from  via )",
          subject: 'PBM - Someone entered a machine condition',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.update_condition('foo')

      expect(@lmx.condition).to eq('foo')
      expect(@lmx.condition_date.to_s).to eq(Time.now.to_s.split(' ')[0])

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "bar\nSassy\nCool Bar\nPortland\n(entered from 0.0.0.0 via cleOS)",
          subject: 'PBM - Someone entered a machine condition',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.update_condition('bar', remote_ip: '0.0.0.0', user_agent: 'cleOS')
    end

    it 'should not send an email for blank condition updates' do
      expect(Pony).to_not receive(:mail)

      @lmx.update_condition('')
    end

    it 'should do nothing if your condition is the same as the previous condition' do
      expect(Pony).to_not receive(:mail)

      @lmx.condition = 'baz'

      @lmx.update_condition('baz')

      expect(MachineCondition.all.count).to eq(0)
      expect(@lmx.condition_date).to be_nil
    end

    it 'should create LocationConditions' do
      @lmx.update_condition('foo')

      expect(MachineCondition.all.count).to eq(1)
      expect(MachineCondition.first.comment).to eq('foo')
    end
  end

  describe '#destroy' do
    it 'should remove the lmx, and email admins if appropriate' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cool Bar\nSassy\nPortland\n(entered from  via )",
          subject: 'PBM - Someone removed a machine from a location',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.destroy

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cool Bar\nSassy\nPortland\n(entered from 0.0.0.0 via cleOS)",
          subject: 'PBM - Someone removed a machine from a location',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.destroy(remote_ip: '0.0.0.0', user_agent: 'cleOS')

      expect(Pony).to_not receive(:mail)

      @lmx_no_email.destroy

      expect(LocationMachineXref.all).to eq([])
    end
  end
end
