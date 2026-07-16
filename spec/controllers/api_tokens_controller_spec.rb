require 'spec_helper'

describe ApiTokensController, type: :controller do
  include ActiveJob::TestHelper

  before(:each) do
    @user = FactoryBot.create(:user)
  end

  describe '#show' do
    render_views

    context 'when logged in' do
      before(:each) { login(@user) }

      it 'renders the request form when the user has no token' do
        get :show
        expect(response).to be_successful
        expect(response.body).to include('Request API Token')
      end

      it 'renders when the user has a pending request' do
        FactoryBot.create(:api_token, user: @user, requested_use: 'testing')
        get :show
        expect(response).to be_successful
      end

      it 'renders the token when the user has an active token' do
        api_token = FactoryBot.create(:api_token, user: @user, requested_use: 'testing')
        api_token.approve!(approved_by: FactoryBot.create(:user))
        get :show
        expect(response).to be_successful
        expect(response.body).to include(api_token.reload.token)
      end
    end

    context 'when logged out' do
      it 'shows the description and a login prompt, but not the form' do
        get :show
        expect(response).to be_successful
        expect(response.body).to include('all API requests must include')
        expect(response.body).not_to include('Request API Token')
        expect(response.body).to include(new_user_session_path)
      end
    end
  end

  describe '#create' do
    before(:each) { login(@user) }

    it 'creates a pending request and notifies super admins' do
      super_admin = FactoryBot.create(:user, is_super_admin: true)

      perform_enqueued_jobs do
        expect {
          post :create, params: { api_token: { requested_use: 'For a scoreboard app' } }
        }.to change(ApiToken, :count).by(1)
      end

      api_token = ApiToken.last
      expect(api_token.user).to eq(@user)
      expect(api_token.requested_use).to eq('For a scoreboard app')
      expect(api_token).to be_pending
      expect(response).to redirect_to(api_token_path)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ ENV.fetch('EMAIL_ADMIN', 'admin@pinballmap.com') ])
      expect(mail.cc).to include(super_admin.email)
      expect(mail.reply_to).to eq([ @user.email ])
    end

    it 'does not allow a second request while one is pending' do
      FactoryBot.create(:api_token, user: @user, requested_use: 'first')

      expect {
        post :create, params: { api_token: { requested_use: 'second' } }
      }.not_to change(ApiToken, :count)

      expect(flash[:error]).to be_present
    end

    it 'does not allow a new request while the user has an active token' do
      api_token = FactoryBot.create(:api_token, user: @user, requested_use: 'first')
      api_token.approve!(approved_by: FactoryBot.create(:user))

      expect {
        post :create, params: { api_token: { requested_use: 'second' } }
      }.not_to change(ApiToken, :count)
    end

    it 'does not allow a new request after revocation' do
      api_token = FactoryBot.create(:api_token, user: @user, requested_use: 'first')
      admin = FactoryBot.create(:user, is_super_admin: true)
      api_token.approve!(approved_by: admin)
      api_token.revoke!(by: admin)

      expect {
        post :create, params: { api_token: { requested_use: 'second' } }
      }.not_to change(ApiToken, :count)
    end

    it 'allows a new request after a denial' do
      api_token = FactoryBot.create(:api_token, user: @user, requested_use: 'first')
      admin = FactoryBot.create(:user, is_super_admin: true)
      api_token.deny!(by: admin)

      expect {
        post :create, params: { api_token: { requested_use: 'second, with more detail' } }
      }.to change(ApiToken, :count).by(1)
    end
  end

  describe '#regenerate' do
    before(:each) { login(@user) }

    it 'disables the active token and issues a new one, emailing the user' do
      api_token = FactoryBot.create(:api_token, user: @user, requested_use: 'first')
      admin = FactoryBot.create(:user, is_super_admin: true)
      api_token.approve!(approved_by: admin)
      old_token = api_token.token

      perform_enqueued_jobs { post :regenerate }

      api_token.reload
      expect(api_token).not_to be_active
      expect(api_token.disabled_reason).to eq('regenerated')

      new_token = ApiToken.active.where(user: @user).first
      expect(new_token.token).not_to eq(old_token)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ @user.email ])
      expect(mail.body.encoded).to include(new_token.token)
    end

    it 'errors when there is no active token' do
      post :regenerate
      expect(flash[:error]).to be_present
    end
  end
end
