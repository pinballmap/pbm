class AddUserIdToUserSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :user_submissions, :user_id, :integer
  end
end
