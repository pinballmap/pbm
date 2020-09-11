class AddSecurityTestToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :security_test, :string
  end
end
