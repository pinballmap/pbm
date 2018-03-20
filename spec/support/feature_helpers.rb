module FeatureHelpers
  include Warden::Test::Helpers

  def login(user = FactoryBot.create(:user))
    login_as(user, scope: :user)
    user
  end

  def logout(user)
    logout(user)
  end
end
