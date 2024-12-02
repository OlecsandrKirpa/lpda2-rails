# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Routing /v2/reservations" do
  it {
    expect(get: "/v2/reservations/valid_times").to route_to("v2/reservations#valid_times", format: :json)
  }
end
