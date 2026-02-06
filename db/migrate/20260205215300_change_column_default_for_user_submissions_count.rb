class ChangeColumnDefaultForUserSubmissionsCount < ActiveRecord::Migration[8.1]
  def self.up
    change_column_default :locations, :user_submissions_count, from: 1, to: 0
  end

  def self.down
    change_column_default :locations, :user_submissions_count, from: 0, to: 1
  end
end
