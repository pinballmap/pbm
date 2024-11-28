class FixUsersTableDefaults < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :num_machines_added, default: 0
    change_column_default :users, :num_machines_removed, default: 0
    change_column_default :users, :num_locations_suggested, default: 0
    change_column_default :users, :num_lmx_comments_left, default: 0
    change_column_default :users, :num_msx_scores_added, default: 0
    change_column_default :users, :user_submissions_count, default: 0
  end
end
