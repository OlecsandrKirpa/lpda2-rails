# frozen_string_literal: true

module V1
  class PublicDataController < ApplicationController
    skip_before_action :authenticate_user

    def index
      reservation = Reservation.public_visible.where(secret: cookies[Reservation::PUBLIC_CREATE_COOKIE],
                                                     datetime: Time.zone.now..).first

      render json: {
        reservation: reservation.as_json(
          only: %w[id fullname datetime status secret children adults notes email phone created_at updated_at],
          include: [
            {
              payment: {
                only: %i[hpp_url status value]
              },
            }
          ]
        ),
        settings: Setting.all.where(key: Setting::PUBLIC_KEYS).pluck(:key, :value).to_h,
        public_messages: PublicMessage.visible.i18n.pluck(:key, :text).to_h,
        contacts: Contact.public_formatted,
      }
    end
  end
end
