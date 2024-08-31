# frozen_string_literal: true

require "rails_helper"

RSpec.context "GET /v1/reservations/valid_times", type: :request do
  let(:date) { Time.zone.now.to_date.to_s }
  let(:params) { { date: } }

  def req(_params = params)
    get "/v1/reservations/valid_times", params: _params
  end

  context "when there are no turns" do
    before do
      ReservationTurn.delete_all
      req
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }
    it { expect(json).to eq [] }
  end

  context "when there are turns: one turn for each day" do
    subject { response }

    before do
      (0..6).each do |weekday|
        ReservationTurn.create!(name: "Day", weekday:, starts_at: "12:00", ends_at: "14:00", step: 30)
      end

      req(date: Time.zone.now.to_date.to_s)
    end

    it { is_expected.to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }

    it {
      expect(json).to all(include("id" => Integer, "starts_at" => String, "ends_at" => String, "weekday" => Integer,
                                  "step" => Integer))
    }

    it { expect(json).to all(include("valid_times" => %w[12:00 12:30 13:00 13:30 14:00])) }
    it { expect(json.count).to eq 1 }
  end

  context "when there are turns: two turns for each day" do
    subject { response }

    before do
      (0..6).each do |weekday|
        ReservationTurn.create!(name: "Lunch", weekday:, starts_at: "12:00", ends_at: "14:00", step: 30)
        ReservationTurn.create!(name: "Dinner1", weekday:, starts_at: "16:00", ends_at: "18:00", step: 30)
      end

      req(date: Time.zone.now.to_date.to_s)
    end

    it { is_expected.to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }

    it {
      expect(json).to all(include("id" => Integer, "starts_at" => String, "ends_at" => String, "weekday" => Integer,
                                  "step" => Integer))
    }

    it { expect(json.count).to eq 2 }

    it {
      expect(json.map do |j|
               j["valid_times"]
             end.flatten.sort).to eq(%w[12:00 12:30 13:00 13:30 14:00 16:00 16:30 17:00 17:30 18:00])
    }
  end
end
