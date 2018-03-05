class AddIsPrimaryEmailContactToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_primary_email_contact, :boolean
  end
end
