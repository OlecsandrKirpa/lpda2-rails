# frozen_string_literal: true

require "rails_helper"

module Nexi
  class ReceiveOrderOutcome < ActiveInteraction::Base
    interface :request, methods: %i[params headers]

    def execute
      OrderOutcomeRequest.create!(body: params, headers:)

      return errors.add(:reservation, "not found") if find_reservation.nil?

      Log::ReservationEvent.create!(
        reservation: find_reservation,
        event_type: "payment_outcome",
        payload: { params:, headers:, ip: request.remote_ip }
      )

      return find_payment.paid! if params.dig!(:esito).to_s.downcase.strip == "ok"

      Rails.logger.warn "Nexi::ReceiveOrderOutcome: Don't know what to do with params: #{params.inspect}, headers: #{headers.inspect}"
    end

    def params
      @params ||= request.params
    end

    def headers
      @headers ||= request.headers.to_s
      # @headers ||= request.headers.to_h
    end

    def find_payment
      @find_payment ||= ::ReservationPayment.find_by!(external_id: params[:codTrans])
    end

    def find_reservation
      @find_reservation ||= find_payment.reservation
    end
  end
end
