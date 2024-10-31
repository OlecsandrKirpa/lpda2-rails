# frozen_string_literal: true

FactoryBot.define do
  factory :reservation_turn do
    weekday { (0..6).to_a.sample }
    starts_at { generate(:starts_and_ends_at_sq) }
    ends_at { (starts_at || Time.zone.now.beginning_of_day) + 1.minute }
    name { generate(:turn_name_seq) }
    step { 30 }
  end

  sequence :starts_and_ends_at_sq do |n|
    Time.zone.now.beginning_of_day + ((n * 2 + 1) % ((24 * 60) - 1)).minutes
  end

  sequence :turn_name_seq do |n|
    "Turn #{n}"
  end
end
