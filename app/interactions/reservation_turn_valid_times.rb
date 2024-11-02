# frozen_string_literal: true

# Given a date, will return an array of times that are available for that ReservationTurn.
class ReservationTurnValidTimes < ActiveInteraction::Base
  record :turn, class: "ReservationTurn"
  string :format, default: "%H:%M"

  # When date is provided, times will be fildered to only include times that are greater than the current time.
  string :date

  def execute
    starts_at = turn.starts_at
    ends_at = turn.ends_at
    times = []

    while starts_at <= ends_at
      times << Time.zone.parse("#{date} #{starts_at.strftime("%H:%M")}")

      starts_at += turn.step.minutes
    end

    if date.to_date == Time.zone.now.to_date
      min_time = Time.zone.now
      if Setting[:reservation_min_hours_in_advance].present?
        min_time += Setting[:reservation_min_hours_in_advance].to_f.hours
      end

      times = times.select do |time|
        time > min_time
      end
    end

    times = delete_times_overlapping_with_weekly_holidays(times)

    times.map { |time| time.strftime(format) }
  end

  def delete_times_overlapping_with_weekly_holidays(times)
    times.reject { |time| Holiday.active_at(time).any? }
  end
end
