require 'spec_helper'

describe LocationsController, type: :controller do
  before(:each) do
    region = FactoryGirl.create(:region, name: 'portland')
    @location = FactoryGirl.create(:location, region: region)
    @machine = FactoryGirl.create(:machine)
    FactoryGirl.create(:user, email: 'foo@bar.com', region: region)
  end

  describe '#newest_machine_name' do
    it 'should tell you the name of the newest machine added to the location' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      FactoryGirl.create(:location_machine_xref, location_id: @location.id, machine: FactoryGirl.create(:machine, name: 'cool'))
      get 'newest_machine_name', region: 'portland', id: @location.id

      expect(response.body).to eq('cool')
    end
  end

  describe ':region/mobile' do
    it 'should route to correct controller' do
      expect(get: '/portland/mobile').to route_to(controller: 'locations', action: 'mobile', region: 'portland')
    end
  end

  describe ':region/iphone.html' do
    it 'should route legacy mobile requests' do
      expect(get: '/portland/iphone.html').to route_to(controller: 'locations', action: 'mobile', region: 'portland')
    end

    it 'redirects to events index with init param 3' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      get 'mobile', region: 'portland', init: 3

      expect(response).to redirect_to '/portland/events.xml'
    end

    it 'redirects to machines index with init param 4' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      get 'mobile', region: 'portland', init: 4

      expect(response).to redirect_to '/portland/machines.xml'
    end

    it 'should send email on new machine creation' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New machine name',
          body: "foo\nTest Location Name\nportland\n(entered from 0.0.0.0 via #{request.user_agent})"
        )
      end

      post 'mobile', region: 'portland', machine_name: 'foo', modify_location: @location.id
    end
  end
end
