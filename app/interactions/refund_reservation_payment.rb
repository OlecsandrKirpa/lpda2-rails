# frozen_string_literal: true

# Given a reservation, will refund its payment.
class RefundReservationPayment < ActiveInteraction::Base
  record :reservation, class: Reservation

  validate do
    # TODO translate all the messages
    errors.add(:reservation, "does not have a payment") unless reservation.payment.present?
    errors.add(:reservation, "is not paid") unless reservation.payment&.paid?
    errors.add(:reservation, "is already refunded") if reservation.payment&.refunded?
    errors.add(:reservation, "is deleted") if reservation.deleted?
    errors.add(:reservation, "value #{reservation.payment&.value.inspect} is invalid") if reservation.payment&.value.to_f <= 0

    if reservation.payment&.paid? && errors.empty? && reservation.datetime < 10.days.ago
      errors.add(:reservation, "too much time has passed. Reservation date was more than 10 days ago. You'll need to refund the payment by Nexi graphical interface. OrderID is #{reservation.payment&.external_id}")
    end
  end

  def execute
    do_refund
    reservation.payment.refunded! if errors.empty? && valid?
  end

  def do_refund
    case reservation.payment.preorder_type
    when "html_nexi_payment"
      call = Nexi::RefundPayment.run(
        value: reservation.payment.value * 100,
        order_id: reservation.payment.external_id,
        request_purpose: "refund_reservation_payment",
        request_record: reservation
      )
      errors.merge!(call.errors) unless call.valid?
    else
      errors.add(:reservation, "payment type #{reservation.payment.preorder_type.inspect} not supported")
    end
  end
end
