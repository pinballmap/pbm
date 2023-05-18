class AddUserSubmissionsCountToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :user_submissions_count, :integer
  end
end
