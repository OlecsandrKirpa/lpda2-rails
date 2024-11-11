# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /v1/admin/stats" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  ALL_KEYS = %w[reservations-by-hour].freeze

  let(:headers) { auth_headers }
  let(:params) { { keys: } }
  let(:keys) { ALL_KEYS }

  def req(p = params, h = headers)
    get "/v1/admin/stats", headers: h, params: p
  end

  context "when not authenticated" do
    let(:headers) { {} }

    it do
      req
      expect(response).to have_http_status(:unauthorized)
    end

    it do
      req
      expect(json).to include(message: String)
    end
  end

  context "when providing one invalid key" do
    let(:keys) { %w[someinvalidkey] }

    before { req }

    it { expect(response).to have_http_status(:bad_request) }
    it { expect(json).to include(message: String) }
    it { expect(json[:message].to_s.downcase).to include("someinvalidkey") }
  end

  context "when not providing any keyM will return all." do
    let(:params) { {} }

    before { req }

    it { expect(response).to be_successful }

    it { expect(json).to be_a(Hash) }

    it { expect(json).not_to be_empty }

    it { expect(json.keys.map(&:to_s)).to match_array(ALL_KEYS) }
  end

  context "when providing all keys" do
    let(:keys) { ALL_KEYS }

    before { req }

    it { expect(response).to be_successful }

    it { expect(json).to be_a(Hash) }

    it { expect(json).not_to be_empty }

    it { expect(json.keys.map(&:to_s)).to match_array(ALL_KEYS) }
  end

  context "when requiring reservations-by-hour as key" do
    let(:keys) { %w[reservations-by-hour] }

    before { req }

    it { expect(response).to be_successful }

    it { expect(json).to be_a(Hash) }
    it { expect(json.keys).to match_array(keys) }

    context "when has two reservation at same datetime" do
      let(:datetime) { DateTime.parse("2021-01-01 10:00:00") }
      let(:res1) { create(:reservation, adults: 1, datetime:) }
      let(:res2) { create(:reservation, adults: 1, datetime:) }

      before do
        create(:reservation_turn, starts_at: "9:00", ends_at: "11:00", weekday: datetime.wday)
        res1
        res2
        req
      end

      it { expect(Reservation.count).to eq 2 }

      it { expect(json["reservations-by-hour"]).to be_a(Hash) }
      it { expect(json["reservations-by-hour"].keys).to contain_exactly("2021-01-01 10:00") }
      it { expect(json["reservations-by-hour"]["2021-01-01 10:00"]).to eq(2) }
    end

    context "when has two reservation at different datetime" do
      let(:datetime1) { DateTime.parse("2021-01-01 10:00:00") }
      let(:datetime2) { DateTime.parse("2021-01-01 11:00:00") }
      let(:res1) { create(:reservation, adults: 1, datetime: datetime1) }
      let(:res2) { create(:reservation, adults: 1, datetime: datetime2) }

      before do
        create(:reservation_turn, starts_at: "9:00", ends_at: "12:00", weekday: datetime1.wday)
        res1
        res2
        req
      end

      it { expect(Reservation.count).to eq 2 }

      it { expect(json["reservations-by-hour"]).to be_a(Hash) }
      it { expect(json["reservations-by-hour"].keys).to contain_exactly("2021-01-01 10:00", "2021-01-01 11:00") }
      it { expect(json["reservations-by-hour"]["2021-01-01 10:00"]).to eq(1) }
      it { expect(json["reservations-by-hour"]["2021-01-01 11:00"]).to eq(1) }
    end

    context "when filtering by date" do
      let(:datetime) { DateTime.parse("2021-01-01 10:00:00") }
      let(:reservations) do
        [
          create(:reservation, adults: 1, datetime:),
          create(:reservation, adults: 1, datetime: datetime + 1.hour),
          create(:reservation, adults: 1, datetime: datetime + 1.day)
        ]
      end

      let(:params) do
        {
          keys:,
          # NOTE: both 'reservation' and 'reservationS' are valid
          reservations_date_from: datetime.to_date,
          reservation_date_to: datetime.to_date
        }
      end

      before do
        create(:reservation_turn, starts_at: "9:00", ends_at: "12:00", weekday: datetime.wday)
        create(:reservation_turn, starts_at: "9:00", ends_at: "12:00", weekday: (datetime + 1.day).wday)
        reservations
        req
      end

      it { expect(Reservation.count).to eq 3 }

      it { expect(json["reservations-by-hour"]).to be_a(Hash) }
      it { expect(json["reservations-by-hour"].keys).to contain_exactly("2021-01-01 10:00", "2021-01-01 11:00") }
      it { expect(json["reservations-by-hour"]["2021-01-01 10:00"]).to eq(1) }
      it { expect(json["reservations-by-hour"]["2021-01-01 11:00"]).to eq(1) }
    end
  end

  context "will return sum of people" do
    let(:datetime) { DateTime.parse("2021-01-01 10:00:00") }

    before do
      create(:reservation_turn, starts_at: "9:00", ends_at: "12:00", weekday: datetime.wday)
      create(:reservation, adults: 7, children: 2, datetime:)
      create(:reservation, adults: 2, datetime:)
      req
    end

    it { expect(Reservation.count).to eq 2 }

    it { expect(json["reservations-by-hour"]).to be_a(Hash) }
    it { expect(json["reservations-by-hour"].keys).to contain_exactly("2021-01-01 10:00") }
    it { expect(json["reservations-by-hour"]["2021-01-01 10:00"]).to eq(11) }
  end
end
