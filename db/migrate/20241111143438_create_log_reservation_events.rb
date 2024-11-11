# frozen_string_literal: true

class CreateLogReservationEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :log_reservation_events do |t|
      t.text :event_type
      t.jsonb :payload
      t.references :reservation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
