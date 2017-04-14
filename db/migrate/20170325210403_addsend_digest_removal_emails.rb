class AddsendDigestRemovalEmails < ActiveRecord::Migration
  def change
    add_column :regions, :send_digest_removal_emails, :boolean
  end
end
