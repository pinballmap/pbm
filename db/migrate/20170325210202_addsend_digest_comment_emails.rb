class AddsendDigestCommentEmails < ActiveRecord::Migration
  def change
    add_column :regions, :send_digest_comment_emails, :boolean
  end
end
