class RemoveRememberTokenFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :remember_token
  end

  def down
    add_column :users, :remember_token, :string
  end
end
