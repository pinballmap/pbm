require 'spec_helper'

describe LocationsController do
  before(:each) do
    ApplicationController.any_instance.stub(:set_current_user).and_return(nil)

    region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location, :region => region)
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => region)
  end

  describe ':region/iphone.html' do
    it 'should route legacy mobile requests' do
      {:get => '/portland/iphone.html'}.should route_to(:controller => 'locations', :action => 'mobile', :region => 'portland')
    end

    it 'should send email on new machine creation' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - New machine name",
          :body => "foo\nTest Location Name\nportland\n(entered via #{request.user_agent})",
        }
      end

      post 'mobile', :region => 'portland', :machine_name => 'foo', :modify_location => @location.id
    end
  end
end
