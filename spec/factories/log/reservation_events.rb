# frozen_string_literal: true

FactoryBot.define do
  factory :log_reservation_event, class: "Log::ReservationEvent" do
    event_type { "do_payment" }
    # payload { {  } }
  end
end
