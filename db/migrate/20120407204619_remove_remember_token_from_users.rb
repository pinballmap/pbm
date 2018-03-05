class RemoveRememberTokenFromUsers < ActiveRecord::Migration[4.2]
  def up
#    remove_column :users, :remember_token
  end

  def down
#    add_column :users, :remember_token, :string
  end
end
