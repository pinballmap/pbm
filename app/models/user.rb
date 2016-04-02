class User < ActiveRecord::Base
  belongs_to :region
  has_many :location_machine_xrefs
  has_many :machine_score_xrefs
  has_many :location_picture_xrefs

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :is_super_admin

  def role_symbols
    roles = []
    roles << :admin if region_id
    roles << :site_admin if (region_id == Region.find_by_name('portland').id)

    roles
  end
end
