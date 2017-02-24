require 'spec_helper'

describe Api::V1::LocationMachineXrefsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, id: 3, name: 'portland', should_email_machine_removal: 1)
    @location = FactoryGirl.create(:location, id: 1, name: 'Ground Kontrol', region: @region)
    @machine = FactoryGirl.create(:machine, id: 2, name: 'Cleo')

    @lmx = FactoryGirl.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    FactoryGirl.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
  end

  describe '#delete' do
    it 'deletes an lmx' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success
      expect(response.status).to eq(200)

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'sends a deletion email when appropriate' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "#{@location.name}\n#{@machine.name}\n#{@location.region.name}\n(user_id: ) (entered from 127.0.0.1 via cleOS)",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', {}, HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'sends a deletion email when appropriate - authed' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "#{@location.name}\n#{@machine.name}\n#{@location.region.name}\n(user_id: 111) (entered from 127.0.0.1 via cleOS by ssw (foo@bar.com))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'creates a user submission for the deletion' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', {}, HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)

      submission = Region.find(@lmx.location.region_id).user_submissions.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq("Ground Kontrol (1)\nCleo (2)\nportland (3)")
    end

    it 'creates a user submission for the deletion - authed' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)

      submission = Region.find(@lmx.location.region_id).user_submissions.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq("Ground Kontrol (1)\nCleo (2)\nportland (3)")
      expect(submission.user_id).to eq(111)
    end

    it 'sends a deletion email when appropriate - notifies if origin was staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Someone removed a machine from a location'
        )
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', {}, HTTP_HOST: 'pinballmapstaging.herokuapp.com'
    end

    it 'errors if lmx id does not exist' do
      delete '/api/v1/location_machine_xrefs/-1.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
      expect(LocationMachineXref.all.size).to eq(1)
    end
  end

  describe '#index' do
    it 'sends all lmxes in region' do
      chicago = FactoryGirl.create(:region, id: 11, name: 'chicago')
      FactoryGirl.create(:location_machine_xref, machine: @machine, location: FactoryGirl.create(:location, id: 11, name: 'Chicago Location', region: chicago))

      get '/api/v1/region/portland/location_machine_xrefs.json'
      expect(response).to be_success

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes.size).to eq(1)

      expect(lmxes[0]['location_id']).to eq(@location.id)
      expect(lmxes[0]['machine_id']).to eq(@machine.id)
    end

    it "only sends the #{MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY} most recent machine_conditions" do
      chicago = FactoryGirl.create(:region, name: 'chicago')
      lmx = FactoryGirl.create(:location_machine_xref, machine: @machine, location: FactoryGirl.create(:location, id: 12, name: 'Chicago Location', region: chicago))

      (MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY + 10).times do
        FactoryGirl.create(:machine_condition, location_machine_xref: lmx.reload, comment: 'Foo')
      end

      get '/api/v1/region/chicago/location_machine_xrefs.json'
      expect(response).to be_success

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes[0]['machine_conditions'].size).to eq(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)
    end

    it 'respects limit scope' do
      newest_lmx = FactoryGirl.create(:location_machine_xref, machine: FactoryGirl.create(:machine, name: 'Barb'), location: @location)

      get '/api/v1/region/portland/location_machine_xrefs.json?limit=1'
      expect(response).to be_success

      expect(JSON.parse(response.body)['location_machine_xrefs'].size).to eq(1)
      expect(JSON.parse(response.body)['location_machine_xrefs'][0]['id']).to eq(newest_lmx.id)
    end
  end

  describe '#create' do
    it 'updates condition on existing lmx' do
      post '/api/v1/location_machine_xrefs.json', machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      updated_lmx = @lmx.reload

      expect(updated_lmx.condition).to eq('foo')
      expect(updated_lmx.condition_date.to_s).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'updates condition on existing lmx - authed' do
      post '/api/v1/location_machine_xrefs.json', machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      updated_lmx = @lmx.reload
      expect(updated_lmx.condition).to eq('foo')
      expect(updated_lmx.condition_date.to_s).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(updated_lmx.location.last_updated_by_user.id).to eq(111)
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'creates new lmx when appropriate' do
      new_machine = FactoryGirl.create(:machine, id: 11, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: 'foo'
      expect(response).to be_success
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      new_lmx = LocationMachineXref.last
      expect(new_lmx.condition).to eq('foo')

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it "doesn't let you add machines that don't exist" do
      post '/api/v1/location_machine_xrefs.json', machine_id: -666, location_id: @location.id.to_s, condition: 'foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'creates new lmx when appropriate - authed' do
      new_machine = FactoryGirl.create(:machine, id: 22, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['last_updated_by_username']).to eq('ssw')

      new_lmx = LocationMachineXref.last
      expect(new_lmx.condition).to eq('foo')
      expect(new_lmx.user_id).to eq(111)

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it 'does not create a machine condition if you pass a blank condition' do
      new_machine = FactoryGirl.create(:machine, id: 22, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success
      expect(response.status).to eq(201)

      expect(MachineCondition.all.size).to eq(0)
    end

    it 'returns an error unless the machine_id and location_id are both present' do
      post '/api/v1/location_machine_xrefs.json'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', machine_id: @machine.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', location_id: @location.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end
  end

  describe '#update' do
    before(:each) do
      @region = FactoryGirl.create(:region, id: 22, name: 'Portland')
      @location = FactoryGirl.create(:location, id: 3, name: 'Ground Kontrol', region: @region)
      @machine = FactoryGirl.create(:machine, id: 4, name: 'Cleo')

      @lmx = FactoryGirl.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)
    end

    it 'updates condition' do
      FactoryGirl.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "foo\nCleo\nGround Kontrol\nPortland\n(entered from 127.0.0.1 via cleOS)",
          subject: 'PBM - Someone entered a machine condition',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, 'condition=foo', HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['comment']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['comment']).to eq('bar')
    end

    it 'updates condition - authed' do
      FactoryGirl.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['last_updated_by_username']).to eq('ssw')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['comment']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['username']).to eq('ssw')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['comment']).to eq('bar')

      @lmx.reload
      expect(@lmx.location.last_updated_by_user.id).to eq(111)
    end

    it 'email notifies if origin was the staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Someone entered a machine condition'
        )
      end

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, { condition: 'foo' }, HTTP_HOST: 'pinballmapstaging.herokuapp.com'
    end

    it 'returns an error message if the lmx does not exist' do
      put '/api/v1/location_machine_xrefs/666?condition=foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end
  end

  describe '#get' do
    it 'sends all detail about this lmx (including machine conditions)' do
      chicago = FactoryGirl.create(:region, id: 11, name: 'chicago')
      lmx = FactoryGirl.create(:location_machine_xref, id: 100, machine: @machine, location: FactoryGirl.create(:location, id: 11, name: 'Chicago Location', region: chicago), condition: 'condition')
      FactoryGirl.create(:machine_condition, id: 1, location_machine_xref: lmx.reload, comment: 'foo')
      FactoryGirl.create(:machine_condition, id: 2, location_machine_xref: lmx.reload, comment: 'bar')

      get '/api/v1/location_machine_xrefs/' + lmx.id.to_s + '.json'
      expect(response).to be_success

      lmx = JSON.parse(response.body)['location_machine']
      machine_conditions = lmx['machine_conditions']

      expect(lmx['condition']).to eq('condition')

      expect(machine_conditions.size).to eq(2)
      expect(machine_conditions[0]['comment']).to eq('bar')
      expect(machine_conditions[1]['comment']).to eq('foo')
    end
  end
end
