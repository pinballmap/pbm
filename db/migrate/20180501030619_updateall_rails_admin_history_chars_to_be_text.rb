class UpdateallRailsAdminHistoryCharsToBeText < ActiveRecord::Migration[5.1]
  def change
    change_column :rails_admin_histories, :message, :text
    change_column :rails_admin_histories, :username, :text
    change_column :rails_admin_histories, :table, :text
  end
end
