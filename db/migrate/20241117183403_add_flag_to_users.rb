class AddFlagToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :flag, :string
  end
end
