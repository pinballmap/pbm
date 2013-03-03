require 'spec_helper'

describe LocationMachineXrefsController do
  before(:each) do
    ApplicationController.any_instance.stub(:set_current_user).and_return(nil)
    @region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location)
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => @region)
  end

  describe 'create' do
    it 'should send email on new machine creation' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - Someone entered a new machine name",
          :body => "foo\nTest Location Name\nportland\n(entered via #{request.user_agent})",
        }
      end

      post 'create', :region => 'portland', :add_machine_by_name => 'foo', :add_machine_by_id => '', :location_id => @location.id
    end
  end
end
