require 'spec_helper'

describe Api::V1::LocationMachineXrefsController do

  describe '#create' do
    before(:each) do
      @region = FactoryGirl.create(:region, :name => 'Portland')
      @location = FactoryGirl.create(:location, :name => 'Ground Kontrol')
      @machine = FactoryGirl.create(:machine, :name => 'Cleo')

      @lmx = FactoryGirl.create(:location_machine_xref, :machine_id => @machine.id, :location_id => @location.id)
    end

    it 'updates condition on existing lmx' do
      post '/api/v1/location_machine_xrefs.json?machine_id=' + @machine.id.to_s + ';location_id=' + @location.id.to_s + ';condition=foo'
      expect(response).to be_success
      JSON.parse(response.body)['location_machine']['condition'].should == 'foo'

      updated_lmx = LocationMachineXref.find(@lmx)
      updated_lmx.condition.should == 'foo'

      LocationMachineXref.all.size.should == 1
    end

    it 'creates new lmx when appropriate' do
      new_machine = FactoryGirl.create(:machine, :name => 'sass')

      post '/api/v1/location_machine_xrefs.json?machine_id=' + new_machine.id.to_s + ';location_id=' + @location.id.to_s + ';condition=foo'
      expect(response).to be_success
      JSON.parse(response.body)['location_machine']['condition'].should == 'foo'

      updated_lmx = LocationMachineXref.find(new_machine)
      updated_lmx.condition.should == 'foo'

      LocationMachineXref.all.size.should == 2
    end
  end

  describe '#update' do
    before(:each) do
      @region = FactoryGirl.create(:region, :name => 'Portland')
      @location = FactoryGirl.create(:location, :name => 'Ground Kontrol')
      @machine = FactoryGirl.create(:machine, :name => 'Cleo')

      @lmx = FactoryGirl.create(:location_machine_xref, :machine_id => @machine.id, :location_id => @location.id)
    end

    it 'updates condition' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "foo\nCleo\nGround Kontrol\nportland\n(entered from 127.0.0.1)",
          :subject => "PBM - Someone entered a machine condition",
          :to => [],
          :from =>"admin@pinballmap.com"
        }
      end

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '?condition=foo'
      expect(response).to be_success
      JSON.parse(response.body)['location_machine']['condition'].should == 'foo'
    end
  end
end
