# frozen_string_literal: true

# Will download all elegible payment statuses.
class UpdateAllReservationPaymentStatusJob
  include Sidekiq::Worker
  sidekiq_options retry: 0, queue: "default"

  def perform
    ReservationPayment.where(
      reservation: Reservation.next.public_visible
    ).pluck(:id).each do |payment_id|
      FetchReservationPaymentStatusJob.perform_async("reservation_payment_id" => payment_id)
    end
  end
end
