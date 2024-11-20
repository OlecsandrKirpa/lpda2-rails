# frozen_string_literal: true

# Payment associated to a reservation.
# Only reservations created when a payment is required will have one.
# If a reservation has one and it's not paid, reservation should not be shown in the dashboard as it's not completed.
class ReservationPayment < ApplicationRecord
  # ################################
  # Constants, settings, modules, et...
  # ################################
  enum status: {
    todo: "todo",
    paid: "paid",
    refounded: "refounded"
  }

  enum preorder_type: {
    # Will require a payment with nexi before reservation can be created.
    # Will send user to nexi payment page. URL will be stored in hpp_url.
    # url_nexi_payment: "url_nexi_payment",

    # NEXI will give us an HTML form to be rendered in our page.
    # The form will basically be a POST request to NEXI.
    # We'll just serve the form to the user as NEXI gave it to us.
    html_nexi_payment: "html_nexi_payment"
  }

  # ################################
  # Associations
  # ################################
  belongs_to :reservation, optional: false
  has_many :nexi_http_requests, through: :reservation

  # ################################
  # Validators
  # ################################
  validates :status, presence: true
  validates :hpp_url, presence: true
  validates :html, presence: true
  validates :preorder_type, presence: true
  validates :external_id, presence: true
  validates :value, presence: true, numericality: { only_integer: false, greater_than: 0 }

  before_validation :gen_hpp_url, if: -> { html.present? }

  def gen_hpp_url
    return if reservation&.secret.blank?

    self.hpp_url ||= Rails.application.routes.url_helpers.do_payment_reservations_url(
      secret: reservation&.secret
      # host: "gigi"
    )
  end

  def clean_html
    html.gsub(/<!--.*?-->/m, "")
  end
end
