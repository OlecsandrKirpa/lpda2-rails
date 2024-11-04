# frozen_string_literal: true

module V1::Admin
  # Responding to /v1/admin/stats/* routes
  class StatsController < ApplicationController
    # GET /v1/admin/stats
    def index
      call = Stats::All.run(params:)
      if call.errors.any? || call.invalid?
        return render_error(status: :bad_request, message: call.errors.full_messages.join(','), details: call.errors.as_json)
      end

      render json: call.result
    end
  end
end
