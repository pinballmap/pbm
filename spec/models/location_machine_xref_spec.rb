require 'spec_helper'

describe LocationMachineXref do
  before(:each) do
    @r = FactoryGirl.create(:region, :name => 'Portland', :should_email_machine_removal => 1)
    @r_no_email = FactoryGirl.create(:region, :should_email_machine_removal => 0)

    @u = FactoryGirl.create(:user, :region => @r, :email => 'foo@bar.com')

    @l = FactoryGirl.create(:location, :region => @r, :name => 'Cool Bar')
    @l_no_email = FactoryGirl.create(:location, :region => @r_no_email)

    @m = FactoryGirl.create(:machine, :name => 'Sassy')

    @lmx = FactoryGirl.create(:location_machine_xref, :location => @l, :machine => @m)
    @lmx_no_email = FactoryGirl.create(:location_machine_xref, :location => @l_no_email, :machine => @m)
  end

  describe '#update_condition' do
    it 'should update the condition of the lmx, timestamp it, and email the admins of the region' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "foo\nSassy\nCool Bar\nPortland\n(entered from )",
          :subject => "PBM - Someone entered a machine condition",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        )
      end

      @lmx.update_condition('foo')

      expect(@lmx.condition).to eq('foo')
      expect(@lmx.condition_date.to_s).to eq(Time.now.to_s)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "bar\nSassy\nCool Bar\nPortland\n(entered from 0.0.0.0)",
          :subject => "PBM - Someone entered a machine condition",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        )
      end

      @lmx.update_condition('bar', {:remote_ip => '0.0.0.0'})
    end
  end

  describe '#destroy' do
    it 'should remove the lmx, and email admins if appropriate' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "Cool Bar\nSassy\nPortland\n(entered from )",
          :subject => "PBM - Someone removed a machine from a location",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        )
      end

      @lmx.destroy

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "Cool Bar\nSassy\nPortland\n(entered from 0.0.0.0)",
          :subject => "PBM - Someone removed a machine from a location",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        )
      end

      @lmx.destroy({:remote_ip => '0.0.0.0'})

      expect(Pony).to_not receive(:mail)

      @lmx_no_email.destroy

      expect(LocationMachineXref.all).to eq([])
    end
  end
end
