# frozen_string_literal: true

# Remind all reservations that are waiting for payment.
class FetchReservationPaymentStatusJob
  include Sidekiq::Worker
  sidekiq_options retry: 0, queue: "default"

  def perform(args)
    FetchReservationPaymentStatus.run!(
      reservation_payment: ReservationPayment.find(args["reservation_payment_id"])
    )
  end
end
