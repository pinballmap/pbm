include Warden::Test::Helpers

module FeatureHelpers
  def login(user = FactoryGirl.create(:user))
    Authorization.current_user = user
    user
  end

  def logout
    Authorization.current_user = nil
  end
end
