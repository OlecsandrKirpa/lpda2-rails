# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :contacts do |t|
      t.text :key, null: false, index: { unique: true }
      t.text :value
      t.text :value_type, null: false, default: "text"

      t.timestamps
    end
  end
end
