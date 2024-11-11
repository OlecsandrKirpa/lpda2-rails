# frozen_string_literal: true

FactoryBot.define do
  factory :nexi_order_outcome_request, class: 'Nexi::OrderOutcomeRequest' do
    body { { some: :thing } }
    headers { { "Content-Type": "application/x-www-form-urlencoded" } }
  end
end
