# frozen_string_literal: true

class AddRootIdToMenuCategories < ActiveRecord::Migration[7.0]
  def change
    add_reference :menu_categories, :root, null: true, foreign_key: { to_table: :menu_categories },
                                           comment: %(Root parent. Will be auto-calculated with before_validation)
  end
end
