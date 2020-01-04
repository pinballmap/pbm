class RegistrationsController < Devise::RegistrationsController
  respond_to :json
  prepend_before_action :create, only: [:create]
  
  def create
    if verify_recaptcha
      @user = User.new(user_params)
        if @user.save
          redirect_to root_path, notice: "Great! Now confirm your account. A confirmation link has been sent to your email address."
        else
          render action: 'new'
        end
    else
      build_resource(sign_up_params)
      clean_up_passwords(resource)
      flash.now[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
      flash.delete :recaptcha_error
      render :new
    end
  end
  
  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :username, :is_disabled, :is_super_admin)
  end
  
end
