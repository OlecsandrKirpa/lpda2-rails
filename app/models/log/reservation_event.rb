# frozen_string_literal: true

module Log
  # Will track some events related to reservations.
  class ReservationEvent < ApplicationRecord
    # ################################
    # Associations
    # ################################
    belongs_to :reservation

    # ################################
    # Validations
    # ################################
    enum event_type: {
      do_payment: "do_payment",
      redirect_payment_success: "redirect_payment_success"
    }

    validates :event_type, presence: true
  end
end
