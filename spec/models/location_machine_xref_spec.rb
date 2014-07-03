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

    Pony.stub(:mail)
  end

  describe '#update_condition' do
    it 'should update the condition of the lmx, timestamp it, and email the admins of the region' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "foo\nSassy\nCool Bar\nPortland\n(entered from )",
          :subject => "PBM - Someone entered a machine condition",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        }
      end

      @lmx.update_condition('foo')

      @lmx.condition.should == 'foo'
      @lmx.condition_date.to_s.should == Time.now.strftime("%Y-%m-%d")

      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "bar\nSassy\nCool Bar\nPortland\n(entered from 0.0.0.0)",
          :subject => "PBM - Someone entered a machine condition",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        }
      end

      @lmx.update_condition('bar', {:remote_ip => '0.0.0.0'})
    end
    it 'should not send an email for blank condition updates' do
      Pony.should_not_receive(:mail)

      @lmx.update_condition('')
    end
  end

  describe '#destroy' do
    it 'should remove the lmx, and email admins if appropriate' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "Cool Bar\nSassy\nPortland\n(entered from )",
          :subject => "PBM - Someone removed a machine from a location",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        }
      end

      @lmx.destroy

      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "Cool Bar\nSassy\nPortland\n(entered from 0.0.0.0)",
          :subject => "PBM - Someone removed a machine from a location",
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com"
        }
      end

      @lmx.destroy({:remote_ip => '0.0.0.0'})

      Pony.should_not_receive(:mail)

      @lmx_no_email.destroy

      LocationMachineXref.all.should == []
    end
  end
end
