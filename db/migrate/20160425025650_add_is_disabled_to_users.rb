class AddIsDisabledToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_disabled, :boolean
  end
end
