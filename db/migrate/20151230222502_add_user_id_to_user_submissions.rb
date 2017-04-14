class AddUserIdToUserSubmissions < ActiveRecord::Migration
  def change
    add_column :user_submissions, :user_id, :integer
  end
end
