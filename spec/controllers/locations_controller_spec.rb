require 'spec_helper'

describe LocationsController do
  before(:each) do
    ApplicationController.any_instance.stub(:set_current_user).and_return(nil)

    region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location, :region => region)
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => region)
  end

  describe '#newest_machine_name' do
    it 'should tell you the name of the newest machine added to the location' do
      FactoryGirl.create(:location_machine_xref, :location => @location, :machine => FactoryGirl.create(:machine, :name => 'cool'))
      get 'newest_machine_name', :region => 'portland', :id => @location.id

      response.body.should == 'cool'
    end
  end

  describe ':region/mobile' do
    it 'should route to correct controller' do
      {:get => '/portland/mobile'}.should route_to(:controller => 'locations', :action => 'mobile', :region => 'portland')
    end
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
          :body => "foo\nTest Location Name\nportland\n(entered from 0.0.0.0 via #{request.user_agent})",
        }
      end

      post 'mobile', :region => 'portland', :machine_name => 'foo', :modify_location => @location.id
    end
  end
end
