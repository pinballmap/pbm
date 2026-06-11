class UsersController < ApplicationController
  rate_limit to: 30, within: 5.minutes, only: :profile, name: "users_profile"

  def fave_locations
    @user = User.find(params[:id])
  end

  def toggle_fave_location
    user = User.find(params[:id])
    location = Location.find(params[:location_id])

    if UserFaveLocation.where(user: user, location: location).any?
      UserFaveLocation.where(user: user, location: location).destroy_all
    else
      UserFaveLocation.create(user: user, location: location)
    end
  end

  def profile
    search_param = params[:id]

    @user = search_param.to_i.to_s == search_param ? User.find_by(id: search_param) : User.find_by_username(search_param)
    raise ActiveRecord::RecordNotFound unless @user

    @life_list_stats = @user.profile_life_list_stats
    @edited_locations = @user.profile_list_of_edited_locations
    @all_machines = Machine.order(:name).select(:id, :name, :year, :manufacturer).map { |m| [ m.name_and_year, m.id ] } if current_user&.id == @user.id
  end

  def update_user_flag
    user = current_user
    user.flag = params[:user_flag]
    user.save
  end

  def render_user_flag
    render partial: "users/render_user_flag", locals: { user: User.find(params[:id]) }
  end
end
