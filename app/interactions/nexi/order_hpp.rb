# frozen_string_literal: true

module Nexi
  # Call Nexi api's at "order_hpp" endpoint.
  # Nexi docs at:
  # https://developer.nexi.it/it/api/post-orders-hpp
  class OrderHpp < ActiveInteraction::Base
    integer :amount
    string :language
    string :order_id
    string :result_url
    string :cancel_url

    # Why this order is being made?
    string :request_purpose
    interface :request_record, methods: %w[id persisted? update], default: nil # Object to associate to http request

    string :currency, default: "EUR"

    attr_reader :client

    def execute
      @client = Client.run(
        params:,
        path: Config.nexi_hpp_payment_path,
        request_purpose:,
        request_record: request_record
      )

      errors.merge!(@client.errors)

      return false if errors.any? || invalid?

      client.json
    end

    def params
      @params ||= {
        order: {
          orderId: order_id,
          amount: amount.to_s,
          currency:
        },
        paymentSession: {
          amount: amount.to_s,

          # ISO 639-2.
          language:,

          resultUrl: result_url,

          cancelUrl: cancel_url
        }
      }
    end
  end
end
