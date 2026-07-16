require 'spec_helper'

describe ApiToken do
  before(:each) do
    @user = FactoryBot.create(:user)
    @super_admin = FactoryBot.create(:user)
  end

  describe 'validations' do
    it 'requires requested_use' do
      api_token = ApiToken.new(user: @user)
      expect(api_token).not_to be_valid
      expect(api_token.errors[:requested_use]).to be_present
    end

    it 'requires token to be present once approved' do
      api_token = FactoryBot.build(:api_token, user: @user, approved_at: Time.current)
      expect(api_token).not_to be_valid
      expect(api_token.errors[:token]).to be_present
    end

    it 'rejects an unrecognized disabled_reason' do
      api_token = FactoryBot.build(:api_token, user: @user, disabled_reason: 'because')
      expect(api_token).not_to be_valid
    end

    it 'only allows one active token per user' do
      first = FactoryBot.create(:api_token, user: @user)
      first.approve!(approved_by: @super_admin)

      second = FactoryBot.create(:api_token, user: @user)
      expect { second.approve!(approved_by: @super_admin) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'state predicates' do
    it 'is pending when neither approved nor disabled' do
      api_token = FactoryBot.create(:api_token, user: @user)
      expect(api_token).to be_pending
      expect(api_token).not_to be_active
      expect(api_token).not_to be_denied
      expect(api_token).not_to be_revoked
    end

    it 'is active once approved' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      expect(api_token).to be_active
      expect(api_token.token).to be_present
      expect(api_token.approved_by).to eq(@super_admin)
    end

    it 'is denied when disabled without ever being approved' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.deny!(by: @super_admin)
      expect(api_token).to be_denied
      expect(api_token.disabled_reason).to eq('denied')
      expect(api_token.disabled_by).to eq(@super_admin)
    end

    it 'is revoked when an active token is disabled for cause' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      api_token.revoke!(by: @super_admin)
      expect(api_token).to be_revoked
      expect(api_token).not_to be_active
    end
  end

  describe '#approve!' do
    it 'raises if the token is not pending' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      expect { api_token.approve!(approved_by: @super_admin) }.to raise_error(ArgumentError)
    end
  end

  describe '#deny!' do
    it 'raises if the token is not pending' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      expect { api_token.deny!(by: @super_admin) }.to raise_error(ArgumentError)
    end
  end

  describe '#revoke!' do
    it 'raises if the token is not active' do
      api_token = FactoryBot.create(:api_token, user: @user)
      expect { api_token.revoke!(by: @super_admin) }.to raise_error(ArgumentError)
    end
  end

  describe '#regenerate!' do
    it 'disables the current token and issues a new active one' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      old_token_value = api_token.token

      new_token = api_token.regenerate!(by: @user)

      expect(api_token.reload).not_to be_active
      expect(api_token.disabled_reason).to eq('regenerated')
      expect(api_token.disabled_by).to eq(@user)
      expect(new_token).to be_active
      expect(new_token.user).to eq(@user)
      expect(new_token.token).not_to eq(old_token_value)
    end

    it 'raises if the token is not active' do
      api_token = FactoryBot.create(:api_token, user: @user)
      expect { api_token.regenerate!(by: @user) }.to raise_error(ArgumentError)
    end

    it 'carries exempt_from_rate_limit forward onto the new token' do
      api_token = FactoryBot.create(:api_token, user: @user, exempt_from_rate_limit: true)
      api_token.approve!(approved_by: @super_admin)

      new_token = api_token.regenerate!(by: @user)

      expect(new_token.exempt_from_rate_limit).to eq(true)
    end
  end

  describe '#disable_for_account_deletion!' do
    it 'disables a pending token' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.disable_for_account_deletion!
      expect(api_token).to be_denied
      expect(api_token.disabled_reason).to eq('account_deleted')
    end

    it 'disables an active token' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      api_token.disable_for_account_deletion!
      expect(api_token).not_to be_active
      expect(api_token.disabled_reason).to eq('account_deleted')
    end

    it 'does not overwrite an existing disabled_reason' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.deny!(by: @super_admin)
      api_token.disable_for_account_deletion!
      expect(api_token.reload.disabled_reason).to eq('denied')
    end
  end

  describe '.currently_revoked?' do
    it 'is false when the user has no tokens' do
      expect(ApiToken.currently_revoked?(@user)).to eq(false)
    end

    it 'is false when the most recent token was regenerated, not revoked' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      api_token.regenerate!(by: @user)

      expect(ApiToken.currently_revoked?(@user)).to eq(false)
    end

    it 'is true when the most recent token was revoked for cause' do
      api_token = FactoryBot.create(:api_token, user: @user)
      api_token.approve!(approved_by: @super_admin)
      api_token.revoke!(by: @super_admin)

      expect(ApiToken.currently_revoked?(@user)).to eq(true)
    end

    it 'is false again if a new token is created after a revocation' do
      old = FactoryBot.create(:api_token, user: @user)
      old.approve!(approved_by: @super_admin)
      old.revoke!(by: @super_admin)

      FactoryBot.create(:api_token, user: @user)

      expect(ApiToken.currently_revoked?(@user)).to eq(false)
    end
  end
end
