class UserFaveLocation < ApplicationRecord
  belongs_to :location
  belongs_to :user

  def rails_admin_default_object_label_method; end
end
