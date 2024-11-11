# frozen_string_literal: true

module V1
  # After the user is sent to the NEXI payment page, NEXI will send a POST request to this endpoint to let us know the outcome of the payment.
  class NexiController < ApplicationController
    skip_before_action :authenticate_user, only: %i[receive_order_outcome]

    # POST /v1/nexi/receive_order_outcome
    # Will manage the outcome of the payment, in
    # application/x-www-form-urlencoded format.
    # https://ecommerce.nexi.it/specifiche-tecniche/codicebase/esito.html
    def receive_order_outcome
      Rails.logger.warn "NexiController#receive_order_outcome: #{params.inspect}, headers: #{request.headers.inspect}"
      Nexi::ReceiveOrderOutcome.run!(request: request)

      render json: {
        status: "ok"
      }
    end
  end
end
