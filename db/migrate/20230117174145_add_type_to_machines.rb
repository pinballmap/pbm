class AddTypeToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :type, :string
  end
end
