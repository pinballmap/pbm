class UsersController < InheritedResources::Base
  respond_to :json

  def profile
    @user = User.find(params[:id])
  end
end
