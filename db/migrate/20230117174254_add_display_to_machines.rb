class AddDisplayToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :display, :string
  end
end
