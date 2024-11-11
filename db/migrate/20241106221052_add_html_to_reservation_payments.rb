# frozen_string_literal: true

class AddHtmlToReservationPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_payments, :html, :text
  end
end
