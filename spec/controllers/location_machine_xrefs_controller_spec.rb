require 'spec_helper'

describe LocationMachineXrefsController, :type => :controller do
  before(:each) do
    expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)
    @region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location)
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => @region)
  end

  describe 'create' do
    it 'should send email on new machine creation' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - New machine name",
          :body => "foo\nTest Location Name\nportland\n(entered from 0.0.0.0 via #{request.user_agent})",
        )
      end

      post 'create', :region => 'portland', :add_machine_by_name => 'foo', :add_machine_by_id => '', :location_id => @location.id
    end
  end
end
