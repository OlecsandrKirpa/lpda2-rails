# frozen_string_literal: true

module Nexi
  # Require nexi a payment link where redirect user
  # Usage:
  # Nexi::CreateReservationPayment.run!(amount: 2000, reservation: Reservation.visible.last)
  class CreateReservationPayment < ActiveInteraction::Base
    record :reservation, class: Reservation
    float :amount

    validate do
      errors.add(:reservation, "has already a payment") if reservation.payment.present? && @payment.blank?
    end

    attr_reader :call

    def execute
      @call = OrderHpp.run(
        amount:,
        language: reservation.lang.lang_to_iso639_2,
        order_id: "reservation_#{reservation.id}_#{Rails.env}",
        result_url:,
        cancel_url:,
        request_purpose: "reservation_payment",
        request_record: reservation
      )

      errors.merge!(call.errors)

      return if errors.any?

      @payment = ::ReservationPayment.create!(
        value: amount,
        hpp_url: call.result["hostedPage"],
        other: { order_hpp_call: call.result },
        reservation:,
        status: :todo,
        preorder_type: :nexi_payment
      )
    end

    def cancel_url
      Mustache.render(
        Config.cancelled_payment_reservation_url, Config.hash.merge(secret: reservation.secret)
      ).gsub(%r{//$/}, "")
    end

    def result_url
      Mustache.render(
        Config.processed_payment_reservation_url, Config.hash.merge(secret: reservation.secret)
      ).gsub(%r{//$/}, "")
    end
  end
end
