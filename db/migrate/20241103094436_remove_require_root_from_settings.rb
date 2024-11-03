# frozen_string_literal: true

class DeleteRequireRootFromSetting < ActiveRecord::Migration[7.0]
  def change
    remove_column :settings, :require_root, :boolean
  end
end
