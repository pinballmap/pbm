class UsersController < InheritedResources::Base
  respond_to :json

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      render action: 'new'
    end
  end

  def profile
    @user = User.find(params[:id])
  end

  private
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :username, :is_disabled, :is_super_admin)
  end
end
