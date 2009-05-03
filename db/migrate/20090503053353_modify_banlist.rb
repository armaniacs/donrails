class ModifyBanlist < ActiveRecord::Migration
  def self.up
    rename_column("banlists", "format", "banformat")
  end

  def self.down
    rename_column("banlists", "banformat", "format")
  end
end
