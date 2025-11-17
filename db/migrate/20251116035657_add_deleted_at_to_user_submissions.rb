class AddDeletedAtToUserSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_submissions, :deleted_at, :datetime
  end
end
