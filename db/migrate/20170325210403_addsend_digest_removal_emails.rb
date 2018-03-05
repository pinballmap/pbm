class AddsendDigestRemovalEmails < ActiveRecord::Migration[4.2]
  def change
    add_column :regions, :send_digest_removal_emails, :boolean
  end
end
