# frozen_string_literal: true

require "rails_helper"

RSpec.context "GET /v1/reservations/valid_dates", type: :request do
  let(:from_date) { (Time.zone.now.to_date - 2.days).to_s }
  let(:to_date) { (Time.zone.now.to_date + 2.days).to_s }
  let(:params) { { from_date:, to_date: } }

  def req(provided_params = params)
    get "/v1/reservations/valid_dates", params: provided_params
  end

  context "when there are no turns" do
    before do
      ReservationTurn.delete_all
      req
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(json).to eq [] }
  end

  context "when there are weekly holidays but dont overlap to any turn" do
    subject { response }

    before do
      (0..6).each do |weekday|
        ReservationTurn.create!(name: "Day", weekday:, starts_at: "12:00", ends_at: "14:00", step: 30)
        create(:holiday, from_timestamp: 10.days.ago, to_timestamp: 10.days.from_now, weekday:,
                         weekly_from: "15:00", weekly_to: "23:59")
        create(:holiday, from_timestamp: 10.days.ago, to_timestamp: 10.days.from_now, weekday:,
                         weekly_from: "00:00", weekly_to: "11:59")
        create(:holiday, from_timestamp: 3.days.ago, to_timestamp: 2.days.ago, weekday:, weekly_from: "00:00",
                         weekly_to: "23:59")
      end

      travel_to Time.zone.now.beginning_of_day do
        req
      end
    end

    it { expect(Holiday.weekly.count).to eq(7 * 3) }
    it { expect(Holiday.count).to eq(7 * 3) }
    it { is_expected.to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }

    it do
      expect(json).to eq([
                           Time.zone.now.to_date.to_s,
                           (Time.zone.now.to_date + 1.day).to_s,
                           (Time.zone.now.to_date + 2.days).to_s
                         ])
    end
  end

  context "when there are weekly holidays that do overlap: returns no dates []" do
    subject { response }

    before do
      (0..6).each do |weekday|
        ReservationTurn.create!(name: "Day", weekday:, starts_at: "12:00", ends_at: "14:00", step: 30)
        create(:holiday, from_timestamp: 3.days.ago, to_timestamp: 3.days.from_now, weekday:,
                         weekly_from: "00:00", weekly_to: "23:59")
      end

      travel_to Time.zone.now.beginning_of_day do
        req
      end
    end

    it { expect(Holiday.weekly.count).to eq(7) }
    it { expect(Holiday.count).to eq(7) }
    it { is_expected.to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }

    it do
      expect(json).to eq([])
    end
  end

  context "when there are turns: one turn for each day" do
    subject { response }

    before do
      (0..6).each do |weekday|
        ReservationTurn.create!(name: "Day", weekday:, starts_at: "12:00", ends_at: "14:00", step: 30)
      end

      travel_to Time.zone.now.beginning_of_day do
        req
      end
    end

    it { is_expected.to have_http_status(:ok) }
    it { expect(json).not_to include(message: String) }

    it do
      expect(json).to eq([
                           Time.zone.now.to_date.to_s,
                           (Time.zone.now.to_date + 1.day).to_s,
                           (Time.zone.now.to_date + 2.days).to_s
                         ])
    end

    context "when querying after all turns ended" do
      before do
        travel_to Time.zone.now.end_of_day do
          req
        end
      end

      it { is_expected.to have_http_status(:ok) }

      it "dates list should not include today" do
        expect(json).to eq([
                             (Time.zone.now.to_date + 1.day).to_s,
                             (Time.zone.now.to_date + 2.days).to_s
                           ])
      end
    end

    context "when setting :reservation_max_days_in_advance to 5, will return from today to 5 days forward" do
      before do
        Setting[:reservation_max_days_in_advance] = 5

        travel_to Time.zone.now.beginning_of_day do
          req({})
        end
      end

      it { is_expected.to have_http_status(:ok) }
      it { expect(json).to eq((Time.zone.now.to_date..(Time.zone.now.to_date + 5.days)).map(&:to_s)) }
    end

    context "when setting reservation_min_hours_in_advance is set, should reflect that." do
      before do
        Setting[:reservation_min_hours_in_advance] = 24

        travel_to Time.zone.now.beginning_of_day do
          req({})
        end
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json).not_to include(message: String) }

      it do
        expect(json[0]).to eq((Time.zone.now + 1.day).to_date.to_s)
      end
    end

    context "when setting both min and max reservation time." do
      before do
        Setting[:reservation_min_hours_in_advance] = 24
        Setting[:reservation_max_days_in_advance] = 5

        travel_to Time.zone.now.beginning_of_day do
          req({})
        end
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json).not_to include(message: String) }

      it do
        expect(json[0]).to eq((Time.zone.now + 1.day).to_date.to_s)
      end

      it { expect(json).to eq((1.day.from_now.to_date..(Time.zone.now.to_date + 5.days)).map(&:to_s)) }
    end
  end
end
