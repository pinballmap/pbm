class AddCountsToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :users_count, :integer, default: 1, null: false
    add_column :locations, :user_submissions_count, :integer, default: 1, null: false
  end
end
