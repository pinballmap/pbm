class AddKineticistUrlToMachines < ActiveRecord::Migration[7.0]
  def change
    add_column :machines, :kineticist_url, :string
  end
end
