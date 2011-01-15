class User < ActiveRecord::Base
  belongs_to :region

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me

  def role_symbols
    roles = Array.new
    roles << :admin if region_id != nil
    roles << :site_admin if (region_id == Region.find_by_name('portland').id)

    roles
  end
end
