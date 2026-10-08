module FeatureHelpers
  include Warden::Test::Helpers

  def login(user = FactoryBot.create(:user))
    login_as(user, scope: :user)
    user
  end

  def logout(_user = nil)
    super(:user)
  end
end
