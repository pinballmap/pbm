class AddShouldEmailMachineRemovalToRegions < ActiveRecord::Migration
  def self.up
    add_column :regions, :should_email_machine_removal, :boolean
  end

  def self.down
    remove_column :regions, :should_email_machine_removal, :boolean
  end
end
