# frozen_string_literal: true

module V2
  class ReservationsController < ApplicationController
    skip_before_action :authenticate_user, only: %i[valid_times]

    # GET /v2/reservations/valid_times?date=<xyz>
    def valid_times
      call = ValidTimesGroupByTurn.run(params:)
      return render_error(status: 400, message: call.errors.full_messages.join(", ")) if call.errors.any? || call.invalid?

      render json: {
        turns: call.result,

        # TODO test holidays presence and format.
        holidays: Holiday.visible.where(":date BETWEEN from_timestamp::date AND to_timestamp::date", date: params[:date]).map{ |h| h.as_json(methods: %w[message ]) },

        # TODO test settings presence and format.
        settings: {
          reservation_max_days_in_advance: Setting[:reservation_max_days_in_advance],
          reservation_min_hours_in_advance: Setting[:reservation_min_hours_in_advance],
        }
      }
    end
  end
end
