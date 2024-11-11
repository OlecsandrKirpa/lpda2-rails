# frozen_string_literal: true

class AddRedirectUrlsToReservationPayment < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_payments, :success_url, :text
    add_column :reservation_payments, :failure_url, :text
  end
end
