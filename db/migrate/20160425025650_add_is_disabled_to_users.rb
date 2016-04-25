class AddIsDisabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_disabled, :boolean
  end
end
