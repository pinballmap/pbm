class AddOptInToOperators < ActiveRecord::Migration[8.1]
  def self.up
    add_column :operators, :email_opt_in, :boolean, default: false, null: false
    add_column :operators, :phone_opt_in, :boolean, default: false, null: false
  end

  def self.down
    remove_column :operators, :email_opt_in
    remove_column :operators, :phone_opt_in
  end
end
