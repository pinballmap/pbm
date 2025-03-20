class RemoveSecurityTestFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :security_test, :string
  end
end
