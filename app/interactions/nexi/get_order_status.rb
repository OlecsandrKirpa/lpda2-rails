# frozen_string_literal: true

module Nexi
  # Get nexi order status.
  # https://ecommerce.nexi.it/specifiche-tecniche/apibackoffice/interrogazionedettaglioordine.html
  class GetOrderStatus < ActiveInteraction::Base
    # ################################
    # Inputs
    # ################################
    string :order_id

    interface :request_record, methods: %w[id persisted? update], default: nil # Object to associate to http request

    # ################################
    # Validators
    # ################################
    validates :order_id, presence: true

    attr_reader :client

    def execute
      @client = Client.run(
        params:,
        path: Config.nexi_order_status_path,
        request_purpose: "nexi_update_order_status",
        request_record:,
        content_type: "application/json",
        mac_part: "apiKey=#{Config.nexi_alias_merchant}codiceTransazione=#{params.dig!(:codiceTransazione)}timeStamp=#{params.dig!(:timeStamp)}"
      )

      errors.merge!(@client.errors)

      validate_response if errors.empty?

      return false if errors.any? || invalid?

      client.json
    end

    def params
      @params ||= {
        codiceTransazione: order_id,
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
