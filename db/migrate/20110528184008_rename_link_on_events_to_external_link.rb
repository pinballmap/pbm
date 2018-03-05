class RenameLinkOnEventsToExternalLink < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :events, :link, :external_link
  end

  def self.down
    rename_column :events, :external_link, :link
  end
end
