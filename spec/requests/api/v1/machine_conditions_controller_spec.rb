require 'spec_helper'

describe Api::V1::MachineConditionsController, type: :request do
  describe '#destroy' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end

    it 'notifies you when it can not find a condition' do
      delete '/api/v1/machine_conditions/1234.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine condition')
    end

    it 'deletes when you own the machine condition' do
      owned_condition = FactoryBot.create(:machine_condition, user: @user, id: 56)

      delete '/api/v1/machine_conditions/' + owned_condition.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['machine_condition']).to eq('Successfully removed machine condition')
      expect(MachineCondition.all.size).to eq(0)
      expect(UserSubmission.where(machine_condition_id: 56).first.deleted_at).to_not eq(nil)
    end

    it 'does not delete when you do not own the machine condition' do
      @evil_user = FactoryBot.create(:user, id: 222, email: 'yeah@ok.com', authentication_token: '123', username: 'sass')
      owned_condition = FactoryBot.create(:machine_condition, user: @user)

      delete '/api/v1/machine_conditions/' + owned_condition.id.to_s + '.json', params: { user_email: 'yeah@ok.com', user_token: '123' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('You can only delete machine conditions that you own')
      expect(MachineCondition.all.size).to eq(1)
    end
  end

  describe '#update' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end

    it 'notifies you when it can not find a condition' do
      put '/api/v1/machine_conditions/123.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', comment: 'bar' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine condition')
    end

    it 'updates when you own the machine condition' do
      owned_condition = FactoryBot.create(:machine_condition, user: @user, comment: 'foo', id: 57)

      put '/api/v1/machine_conditions/' + owned_condition.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', comment: 'bar' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['machine_condition']).to eq('Successfully updated machine condition')
      expect(MachineCondition.first.comment).to eq('bar')
      expect(UserSubmission.where(machine_condition_id: 57).first.comment).to eq('bar')
    end

    it 'does not update when you do not own the machine condition' do
      @evil_user = FactoryBot.create(:user, id: 222, email: 'yeah@ok.com', authentication_token: '123', username: 'sass')
      owned_condition = FactoryBot.create(:machine_condition, user: @user, comment: 'foo')

      put '/api/v1/machine_conditions/' + owned_condition.id.to_s + '.json', params: { user_email: 'yeah@ok.com', user_token: '123', comment: 'bar' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('You can only update machine conditions that you own')
      expect(MachineCondition.first.comment).to eq('foo')
    end
  end
end
