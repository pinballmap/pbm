module ControllerHelpers
  include Warden::Test::Helpers

  def login(user = double('user'))
    allow_message_expectations_on_nil
    if user.nil?
      allow(request.env['warden']).to receive(:authenticate!).and_throw(:warden, scope: :user)
      allow(controller).to receive(:current_user).and_return(nil)
    else
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive(:current_user).and_return(user)
      login_as(user, scope: :user)
    end
  end

  def logout
    @current_user = nil
  end
end
