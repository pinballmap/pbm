class FixAdminRankColumnName < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :admin_rank, :admin_title
  end
end
