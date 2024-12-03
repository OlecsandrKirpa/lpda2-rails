# frozen_string_literal: true

class ReservationTurnToMessage < ApplicationRecord
  # ################################
  # Associations
  # ################################
  belongs_to :reservation_turn
  belongs_to :reservation_turn_message

  alias_attribute :turn, :reservation_turn
  alias_attribute :message, :reservation_turn_message
end
