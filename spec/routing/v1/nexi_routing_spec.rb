# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /v1/nexi/receive_order_outcome", type: :routing do
  it "routes to #receive_order_outcome" do
    expect(post: "/v1/nexi/receive_order_outcome").to route_to("v1/nexi#receive_order_outcome", format: :json)
  end
end
