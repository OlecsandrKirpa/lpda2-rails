# frozen_string_literal: true

module V1
  class ImagesController < ApplicationController
    before_action :find_item, only: %i[download download_variant]
    before_action :find_variant, only: %i[download_variant]
    skip_before_action :authenticate_user, only: %i[download download_variant]

    def download
      serve_image @image
    end

    def download_variant
      serve_image @variant
    end

    private

    def serve_image(image)
      return render_error(status: 500, message: 'attached_image is missing') unless image.attached_image.present?

      send_data image.download, type: image.content_type, disposition: 'inline'
    rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ActiveStorage::FileUnpreviewable
      render_error(status: 500, message: 'Error on download')
    end

    def find_item
      @image = Image.visible.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_error(status: 404, message: "#{I18n.t('record_not_found', model: Image, id: params[:id].inspect)}")
    end

    def find_variant
      @variant = @image.find_variant!(params[:variant].to_s)
    rescue ActiveRecord::RecordNotFound
      render_error(status: 404, message: "#{I18n.t('record_not_found', model: Image, id: params[:id].inspect)}#{params[:variant].present? ? " with variant #{params[:variant].inspect}" : ''}")
    end
  end
end
