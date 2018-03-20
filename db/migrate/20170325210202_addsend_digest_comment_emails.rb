class AddsendDigestCommentEmails < ActiveRecord::Migration[4.2]
  def change
    add_column :regions, :send_digest_comment_emails, :boolean
  end
end
