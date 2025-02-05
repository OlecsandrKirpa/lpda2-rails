# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    key { Setting::DEFAULTS.keys.sample }
    value { nil }
  end
end
