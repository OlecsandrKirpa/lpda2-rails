# frozen_string_literal: true

module Nexi
  # https://ecommerce.nexi.it/specifiche-tecniche/apibackoffice/stornorimborso.html
  class RefundPayment < ActiveInteraction::Base
    # ################################
    # Inputs
    # ################################
    integer :value # in cents
    string :order_id
    string :request_purpose

    interface :request_record, methods: %w[id persisted? update], default: nil # Object to associate to http request

    # ################################
    # Validators
    # ################################
    validates :value, presence: true, numericality: { greater_than: 0, only_integer: true }
    validates :order_id, presence: true
    validates :request_purpose, presence: true

    attr_reader :client

    def execute
      @client = Client.run(
        params:,
        path: Config.nexi_refund_payment_path,
        request_purpose:,
        request_record:,
        content_type: "application/json",
        mac_part: "apiKey=#{Config.nexi_alias_merchant}codiceTransazione=#{params.dig!(:codiceTransazione)}divisa=#{params.dig!(:divisa)}importo=#{params.dig!(:importo)}timeStamp=#{params.dig!(:timeStamp)}"
      )

      errors.merge!(@client.errors)

      validate_response if errors.empty?

      return false if errors.any? || invalid?

      client.json
    end

    def params
      @params ||= {
        codiceTransazione: order_id,
        importo: value.to_s,
        divisa: 978,
        timeStamp: Time.zone.now.to_i * 1000
      }
    end

    def validate_response
      e = []
      e << "is blank" if client.json.blank? && client.html.blank?
      e << "is not a hash" if e.empty? && !client.json.is_a?(Hash)
      e << "field 'esito' is not 'ok'" if e.empty? && client.json.dig("esito").to_s.downcase != "ok"

      errors.add(:client, "invalid response #{client.json.inspect}: #{e.join(", ")}") if e.any?
    end
  end
end
