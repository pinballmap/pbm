class RenameLinkOnEventsToExternalLink < ActiveRecord::Migration
  def self.up
    rename_column :events, :link, :external_link
  end

  def self.down
    rename_column :events, :external_link, :link
  end
end
