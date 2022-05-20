require 'spec_helper'

describe Api::V1::LocationMachineXrefsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, id: 3, name: 'portland', should_email_machine_removal: 1)
    @location = FactoryBot.create(:location, id: 1, name: 'Ground Kontrol', region: @region)
    @machine = FactoryBot.create(:machine, id: 2, name: 'Cleo')

    @lmx = FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
  end

  describe '#delete' do
    it 'deletes an lmx' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(200)

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'sends a deletion email when appropriate' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "#{@location.name}\n#{@location.city}\n#{@machine.name}\n#{@location.region.name}\n(user_id: 111) (entered from 127.0.0.1 via cleOS by ssw (foo@bar.com))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'sends a deletion email when appropriate - authed' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "#{@location.name}\n#{@location.city}\n#{@machine.name}\n#{@location.region.name}\n(user_id: 111) (entered from 127.0.0.1 via cleOS by ssw (foo@bar.com))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'creates a user submission for the deletion' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)

      submission = Region.find(@lmx.location.region_id).user_submissions.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq('Cleo was removed from Ground Kontrol in Portland by ssw')
    end

    it 'creates a user submission for the deletion - authed' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)

      submission = Region.find(@lmx.location.region_id).user_submissions.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq('Cleo was removed from Ground Kontrol in Portland by ssw')
      expect(submission.user_id).to eq(111)
    end

    it 'sends a deletion email when appropriate - notifies if origin was staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Someone removed a machine from a location'
        )
      end

      host! 'pinballmapstaging.herokuapp.com'
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
    end

    it 'errors if lmx id does not exist' do
      delete '/api/v1/location_machine_xrefs/-1.json'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'errors if not authed' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', {}
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
      expect(LocationMachineXref.all.size).to eq(1)
    end
  end

  describe '#index' do
    it 'sends all lmxes in region' do
      chicago = FactoryBot.create(:region, id: 11, name: 'chicago')
      FactoryBot.create(:location_machine_xref, machine: @machine, location: FactoryBot.create(:location, id: 11, name: 'Chicago Location', region: chicago))

      get '/api/v1/region/portland/location_machine_xrefs.json'
      expect(response).to be_successful

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes.size).to eq(1)

      expect(lmxes[0]['location_id']).to eq(@location.id)
      expect(lmxes[0]['machine_id']).to eq(@machine.id)
    end

    it "only sends the #{MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY} most recent machine_conditions" do
      chicago = FactoryBot.create(:region, name: 'chicago')
      lmx = FactoryBot.create(:location_machine_xref, machine: @machine, location: FactoryBot.create(:location, id: 12, name: 'Chicago Location', region: chicago))

      (MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY + 10).times do
        FactoryBot.create(:machine_condition, location_machine_xref: lmx.reload, comment: 'Foo')
      end

      get '/api/v1/region/chicago/location_machine_xrefs.json'
      expect(response).to be_successful

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes[0]['machine_conditions'].size).to eq(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)
    end

    it 'respects limit scope' do
      newest_lmx = FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, name: 'Barb'), location: @location)

      get '/api/v1/region/portland/location_machine_xrefs.json?limit=1'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['location_machine_xrefs'].size).to eq(1)
      expect(JSON.parse(response.body)['location_machine_xrefs'][0]['id']).to eq(newest_lmx.id)
    end
  end

  describe '#create' do
    it 'updates condition on existing lmx' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      updated_lmx = @lmx.reload

      expect(updated_lmx.condition).to eq('foo')
      expect(updated_lmx.condition_date.to_s).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'updates condition on existing lmx - authed' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      updated_lmx = @lmx.reload
      expect(updated_lmx.condition).to eq('foo')
      expect(updated_lmx.condition_date.to_s).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(updated_lmx.location.last_updated_by_user.id).to eq(111)
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'creates new lmx when appropriate' do
      new_machine = FactoryBot.create(:machine, id: 11, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')

      new_lmx = LocationMachineXref.last
      expect(new_lmx.condition).to eq('foo')

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it "doesn't let you add machines that don't exist" do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: -666, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'creates new lmx when appropriate - authed' do
      new_machine = FactoryBot.create(:machine, id: 22, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['last_updated_by_username']).to eq('ssw')

      new_lmx = LocationMachineXref.last
      expect(new_lmx.condition).to eq('foo')
      expect(new_lmx.user_id).to eq(111)

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it 'does not create a machine condition if you pass a blank condition' do
      new_machine = FactoryBot.create(:machine, id: 22, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(MachineCondition.all.size).to eq(0)
    end

    it 'returns an error unless the machine_id and location_id are both present' do
      post '/api/v1/location_machine_xrefs.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', params: { location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'returns an error if you are not authenticated' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: 123, location_id: @location.id.to_s, condition: 'foo' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
    end
  end

  describe '#update' do
    before(:each) do
      @region = FactoryBot.create(:region, id: 22, name: 'Portland')
      @location = FactoryBot.create(:location, id: 3, name: 'Ground Kontrol', region: @region)
      @machine = FactoryBot.create(:machine, id: 4, name: 'Cleo')

      @lmx = FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)
    end

    it 'updates condition' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "foo\nCleo\nGround Kontrol\nPortland\nPortland\n(entered from 127.0.0.1 via cleOS by ssw (foo@bar.com))",
          subject: 'PBM - Someone entered a machine condition',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['comment']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['comment']).to eq('bar')
    end

    it 'updates condition - authed' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['condition']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['last_updated_by_username']).to eq('ssw')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['comment']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['username']).to eq('ssw')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['comment']).to eq('bar')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['username']).to eq('')

      @lmx.reload
      expect(@lmx.location.last_updated_by_user.id).to eq(111)
    end

    it 'email notifies if origin was the staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Someone entered a machine condition'
        )
      end

      host! 'pinballmapstaging.herokuapp.com'
      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
    end

    it 'returns an error message if the lmx does not exist' do
      put '/api/v1/location_machine_xrefs/666?condition=foo'
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'returns an error message if you are not authed' do
      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', HTTP_HOST: 'pinballmapstaging.herokuapp.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
    end
  end

  describe '#get' do
    it 'sends all detail about this lmx (including machine conditions)' do
      chicago = FactoryBot.create(:region, id: 11, name: 'chicago')
      lmx = FactoryBot.create(:location_machine_xref, id: 100, machine: @machine, location: FactoryBot.create(:location, id: 11, name: 'Chicago Location', region: chicago), condition: 'condition')
      FactoryBot.create(:machine_condition, id: 1, location_machine_xref: lmx.reload, comment: 'foo')
      FactoryBot.create(:machine_condition, id: 2, location_machine_xref: lmx.reload, comment: 'bar')

      get '/api/v1/location_machine_xrefs/' + lmx.id.to_s + '.json'
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      machine_conditions = lmx['machine_conditions']

      expect(lmx['condition']).to eq('condition')

      expect(machine_conditions.size).to eq(2)
      expect(machine_conditions[0]['comment']).to eq('bar')
      expect(machine_conditions[1]['comment']).to eq('foo')
    end
  end

  describe '#top_n_machines' do
    it 'sends back the top N machines' do
      chicago = FactoryBot.create(:region)

      first_machine = FactoryBot.create(:machine, id: 1111, name: 'machine 1 (LE)', opdb_id: 'b33fy-ch33s')
      second_machine = FactoryBot.create(:machine, id: 2222, name: 'machine 1 (Pro)', opdb_id: 'b33fy-t2cos')
      third_machine = FactoryBot.create(:machine, id: 3333, name: 'machine 2', opdb_id: 'ch33s')
      fourth_machine = FactoryBot.create(:machine, id: 4444, name: 'machine 3', opdb_id: 'gr@vy')

      2.times do |index|
        FactoryBot.create(:location_machine_xref, machine: first_machine, location: FactoryBot.create(:location, id: 111 + index, region: chicago))
      end

      2.times do |index|
        FactoryBot.create(:location_machine_xref, machine: second_machine, location: FactoryBot.create(:location, id: 222 + index, region: chicago))
        FactoryBot.create(:location_machine_xref, machine: third_machine, location: FactoryBot.create(:location, id: 333 + index, region: chicago))
      end

      FactoryBot.create(:location_machine_xref, machine: fourth_machine, location: FactoryBot.create(:location, id: 444, region: chicago))

      get '/api/v1/location_machine_xrefs/top_n_machines.json?n=2'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']
      expect(machines.size).to eq(2)

      expect(machines[0]['machine_name']).to eq('machine 1')
      expect(machines[1]['machine_name']).to eq('machine 2')
    end

    it 'defaults to top 25' do
      ActiveRecord::Base.connection.tables.each do |t|
        ActiveRecord::Base.connection.reset_pk_sequence!(t)
      end

      30.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s, opdb_id: 'b33' + index.to_s), location: FactoryBot.create(:location))
      end

      get '/api/v1/location_machine_xrefs/top_n_machines.json'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']

      expect(machines.size).to eq(25)
    end
  end
end
