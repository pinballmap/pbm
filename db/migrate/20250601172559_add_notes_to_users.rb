class AddNotesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :notes, :string
  end
end
