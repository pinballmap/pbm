class AddIsPrimaryEmailContactToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_primary_email_contact, :boolean
  end
end
