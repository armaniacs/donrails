class Plugin < ActiveRecord::Base
  validates_presence_of :name, :description, :manifest, :activation
end # class Plugin
