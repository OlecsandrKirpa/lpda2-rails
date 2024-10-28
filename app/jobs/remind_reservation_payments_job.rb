# frozen_string_literal: true

# Remind all reservations that are waiting for payment.
class RemindReservationPaymentsJob
  include Sidekiq::Worker
  sidekiq_options retry: 0, queue: "default"

  def perform
    RemindReservationPayments.run!
  end
end
