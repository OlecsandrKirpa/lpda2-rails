# frozen_string_literal: true

FactoryBot.define do
  factory :reservation_payment do
    # hpp_url { "https://secure.payment-provider.example.com?id=#{SecureRandom.hex}" }
    html { "<form action='https://secure.payment-provider.example.com' method='post'><input type='hidden' name='id' value='#{SecureRandom.hex}'></form>" }
    value { 30 }
    status { "todo" }
    preorder_type { "html_nexi_payment" }
    external_id { SecureRandom.hex }
  end
end
