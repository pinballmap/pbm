require 'spec_helper'

describe Api::V1::LocationMachineXrefsController do
  before(:each) do
    @region = FactoryGirl.create(:region, :name => 'portland', :should_email_machine_removal => 1)
    @location = FactoryGirl.create(:location, :name => 'Ground Kontrol', :region => @region)
    @machine = FactoryGirl.create(:machine, :name => 'Cleo')

    @lmx = FactoryGirl.create(:location_machine_xref, :machine_id => @machine.id, :location_id => @location.id)
  end

  describe '#delete' do
    it 'deletes an lmx' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      LocationMachineXref.all.size.should == 0
    end

    it 'sends a deletion email when appropriate' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "#{@location.name}\n#{@machine.name}\n#{@location.region.name}\n(entered from )",
          :subject => "PBM - Someone removed a machine from a location",
          :to => [],
          :from =>"admin@pinballmap.com"
        }
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      LocationMachineXref.all.size.should == 0
    end

    it 'errors if lmx id does not exist' do
      delete '/api/v1/location_machine_xrefs/-1.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
      LocationMachineXref.all.size.should == 1
    end
  end

  describe '#index' do
    it 'sends all lmxes in region' do
      chicago = FactoryGirl.create(:region, :name => 'chicago')
      FactoryGirl.create(:location_machine_xref, :machine => @machine, :location => FactoryGirl.create(:location, :name => 'Chicago Location', :region => chicago))

      get '/api/v1/region/portland/location_machine_xrefs.json'
      expect(response).to be_success

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      lmxes.size.should == 1

      lmxes[0]['location_id'].should == @location.id
      lmxes[0]['machine_id'].should == @machine.id
    end

    it 'respects limit scope' do
      newest_lmx = FactoryGirl.create(:location_machine_xref, :machine => FactoryGirl.create(:machine, :name => 'Barb'), :location => @location);

      get '/api/v1/region/portland/location_machine_xrefs.json?limit=1'
      expect(response).to be_success

      JSON.parse(response.body)['location_machine_xrefs'].size.should == 1
      JSON.parse(response.body)['location_machine_xrefs'][0]['id'].should == newest_lmx.id
    end
  end

  describe '#create' do
    it 'updates condition on existing lmx' do
      post '/api/v1/location_machine_xrefs.json?machine_id=' + @machine.id.to_s + ';location_id=' + @location.id.to_s + ';condition=foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      updated_lmx = LocationMachineXref.find(@lmx)
      updated_lmx.condition.should == 'foo'

      LocationMachineXref.all.size.should == 1
    end

    it 'creates new lmx when appropriate' do
      new_machine = FactoryGirl.create(:machine, :name => 'sass')

      post '/api/v1/location_machine_xrefs.json?machine_id=' + new_machine.id.to_s + ';location_id=' + @location.id.to_s + ';condition=foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      new_lmx = LocationMachineXref.last
      new_lmx.condition.should == 'foo'

      LocationMachineXref.all.size.should == 2
    end
  end

  describe '#update' do
    before(:each) do
      @region = FactoryGirl.create(:region, :name => 'Portland')
      @location = FactoryGirl.create(:location, :name => 'Ground Kontrol', :region => @region)
      @machine = FactoryGirl.create(:machine, :name => 'Cleo')

      @lmx = FactoryGirl.create(:location_machine_xref, :machine_id => @machine.id, :location_id => @location.id)
    end

    it 'updates condition' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :body => "foo\nCleo\nGround Kontrol\nPortland\n(entered from 127.0.0.1)",
          :subject => "PBM - Someone entered a machine condition",
          :to => [],
          :from =>"admin@pinballmap.com"
        }
      end

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '?condition=foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
    end
  end
end
