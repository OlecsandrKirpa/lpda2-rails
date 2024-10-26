# frozen_string_literal: true

class RemindReservationsMail < ActiveInteraction::Base
  def execute
    Reservation.next.where(
      "datetime IS BETWEEN ? AND ?", Time.zone.now, Time.zone.now + 1.day
    ).each do |reservation|
      ReservationMailer.with(reservation_id: reservation.id).reminder.deliver_later
    end
  end
end
