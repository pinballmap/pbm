class RegistrationsController < Devise::RegistrationsController
  respond_to :json
  prepend_before_action :create, only: [:create]

  def create
    @answers = %w[pinball Pinball PINBALL]
    @user = User.new(user_params)
    if @answers.any? { |w| @user.security_test[w] }
      if @user.save
        redirect_to root_path, notice: 'Great! Now confirm your account. A confirmation link has been sent to your email address.'
      else
        render action: 'new'
      end
    else
      build_resource(sign_up_params)
      clean_up_passwords(resource)
      flash.now[:alert] = 'You failed the security test. Please go back and try again.'
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :security_test, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :username, :is_disabled, :is_super_admin)
  end
end
