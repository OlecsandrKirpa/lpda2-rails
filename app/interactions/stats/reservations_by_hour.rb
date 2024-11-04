# frozen_string_literal: true

module Stats
  # Get reservations grouped by hour.
  class ReservationsByHour < ActiveInteraction::Base
    interface :params, methods: %i[keys []], default: {}

    def execute
      reservations.limit(10_000).group_by do |reservation|
        reservation.datetime.strftime(group_format)
      end.transform_values { |rs| rs.map { |r| r.people }.sum }
    end

    def group_format
      params[:group_format] || "%Y-%m-%d %H:%M"
    end

    def reservations
      return @reservations if defined?(@reservations)

      @reservations = SearchReservations.run!(
        reservations: Reservation.visible,
        params: reservation_filters
      )
    end

    # To filter by reservations, you can provide:
    # - reservation_status: String
    # - reservation_from_date: Date
    def reservation_filters
      @reservation_filters ||= params.keys.filter { |key| key.start_with?("reservation") }.map do |key|
        [
          key.split("_")[1..].join("_").to_sym,
          params[key]
        ]
      end.to_h
    end
  end
end
