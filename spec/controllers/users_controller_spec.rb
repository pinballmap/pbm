require 'spec_helper'

describe UsersController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.test')
    @other_user = FactoryBot.create(:user, username: 'acidburn', email: 'crash@override.test')
    @location = FactoryBot.create(:location)
  end

  describe 'toggle_fave_location' do
    it 'requires a logged in user' do
      post :toggle_fave_location, format: :json, params: { id: @other_user.id, location_id: @location.id }

      expect(response).to have_http_status(:unauthorized)
      expect(UserFaveLocation.count).to eq(0)
    end

    it "toggles the current user's fave, ignoring the user id in the url" do
      login(@user)

      post :toggle_fave_location, format: :json, params: { id: @other_user.id, location_id: @location.id }

      expect(UserFaveLocation.where(user: @user, location: @location)).to exist
      expect(UserFaveLocation.where(user: @other_user)).not_to exist

      post :toggle_fave_location, format: :json, params: { id: @user.id, location_id: @location.id }

      expect(UserFaveLocation.count).to eq(0)
    end
  end

  describe 'update_user_flag' do
    it 'requires a logged in user' do
      post :update_user_flag, format: :json, params: { id: @user.id, user_flag: 'us' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
