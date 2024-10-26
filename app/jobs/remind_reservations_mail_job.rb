# frozen_string_literal: true

# Remind all reservations that are scheduled for the next day.
class RemindReservationsMailJob
  include Sidekiq::Worker
  sidekiq_options retry: 0, queue: "default"

  def perform
    RemindReservationsMail.run!
  end
end
