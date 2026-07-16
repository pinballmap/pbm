require 'spec_helper'

describe ApiTokenApprovalsController, type: :controller do
  include ActiveJob::TestHelper

  before(:each) do
    @requester = FactoryBot.create(:user)
    @super_admin = FactoryBot.create(:user, region: FactoryBot.create(:region), is_super_admin: true)
    @region_admin = FactoryBot.create(:user, region: FactoryBot.create(:region), is_super_admin: false)
  end

  describe '#approve' do
    it 'approves a pending request and emails the user' do
      login(@super_admin)
      api_token = FactoryBot.create(:api_token, user: @requester, requested_use: 'testing')

      perform_enqueued_jobs { post :approve, params: { id: api_token.id } }

      api_token.reload
      expect(api_token).to be_active
      expect(api_token.approved_by).to eq(@super_admin)
      expect(response).to redirect_to("/admin/api_token/#{api_token.id}")

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ @requester.email ])
      expect(mail.body.encoded).to include(api_token.token)
    end

    it 'is denied to a region admin who is not a super admin' do
      login(@region_admin)
      api_token = FactoryBot.create(:api_token, user: @requester, requested_use: 'testing')

      post :approve, params: { id: api_token.id }

      expect(api_token.reload).to be_pending
    end
  end

  describe '#deny' do
    it 'denies a pending request without generating a token, and emails the user' do
      login(@super_admin)
      api_token = FactoryBot.create(:api_token, user: @requester, requested_use: 'testing')

      perform_enqueued_jobs { post :deny, params: { id: api_token.id } }

      api_token.reload
      expect(api_token).to be_denied
      expect(api_token.disabled_by).to eq(@super_admin)
      expect(api_token.token).to be_nil

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ @requester.email ])
      expect(mail.subject).to eq("Pinball Map - Your API token request was not approved")
    end
  end

  describe '#revoke' do
    it 'revokes an active token' do
      login(@super_admin)
      api_token = FactoryBot.create(:api_token, user: @requester, requested_use: 'testing')
      api_token.approve!(approved_by: @super_admin)

      post :revoke, params: { id: api_token.id }

      api_token.reload
      expect(api_token).to be_revoked
      expect(api_token.disabled_by).to eq(@super_admin)
      expect(ApiToken.currently_revoked?(@requester)).to eq(true)
    end
  end

  describe '#regenerate' do
    it 'issues a new token on behalf of the user' do
      login(@super_admin)
      api_token = FactoryBot.create(:api_token, user: @requester, requested_use: 'testing')
      api_token.approve!(approved_by: @super_admin)
      old_token = api_token.token

      post :regenerate, params: { id: api_token.id }

      api_token.reload
      expect(api_token).not_to be_active

      new_token = ApiToken.active.where(user: @requester).first
      expect(new_token.token).not_to eq(old_token)
      expect(response).to redirect_to("/admin/api_token/#{new_token.id}")
    end
  end
end
