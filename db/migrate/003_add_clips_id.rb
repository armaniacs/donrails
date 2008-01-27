class AddClipsId < ActiveRecord::Migration
  def self.up
    add_column :don_envs, "add_clips_id", :string
    add_column :don_envs, "default_format", :string, :default => "wiliki"
  end

  def self.down
    remove_column :don_envs, "add_clips_id"
    remove_column :don_envs, "default_format"
  end
end
