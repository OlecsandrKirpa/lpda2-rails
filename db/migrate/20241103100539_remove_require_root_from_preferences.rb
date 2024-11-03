# frozen_string_literal: true

class RemoveRequireRootFromPreferences < ActiveRecord::Migration[7.0]
  def change
    remove_column :preferences, :require_root, :boolean
  end
end
