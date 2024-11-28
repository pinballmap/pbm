class AddAdminRankToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :admin_rank, :string
  end
end
