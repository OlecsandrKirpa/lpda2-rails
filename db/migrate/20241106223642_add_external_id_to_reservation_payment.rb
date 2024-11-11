# frozen_string_literal: true

class AddExternalIdToReservationPayment < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_payments, :external_id, :text
  end
end
