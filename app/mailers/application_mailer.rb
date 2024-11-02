# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Config.app.dig(:emails, :default_from),
          reply_to: Config.app.dig(:emails, :default_reply_to) || Config.app.dig(:emails, :default_from)

  layout "mailer"

  before_action do
    headers "X-ApplicationSender" => "lpda2"

    @images = Image.where("key ILIKE 'email_images_%'").all.map do |image|
      [
        image.key.split("email_images_").last,
        image.download_by_key_url
      ]
    end.to_h.with_indifferent_access

    if params && params[:pixels].is_a?(Hash)
      params[:pixels].each do |key, id|
        @images[key] = Log::ImagePixel.find(id).url
      end
    end

    @contacts = Contact.public_formatted
  end

  after_action do
    delivered_email = params[:delivered_email] || Log::DeliveredEmail.find_by(id: params[:delivered_email_id]) || Log::DeliveredEmail.create!

    delivered_email.update!(
      {
        controller_path:,
        action_name:,
        text: mail.text_part&.body&.decoded,
        html: mail.html_part&.body&.decoded,
        subject: mail.subject,
        headers: mail.header.fields.map { |field| [field.name, field.value] }.to_h,
        raw: mail.to_s,
        record: detect_record
      }.compact
    )
  end

  around_action do |_, block|
    I18n.with_locale(detect_locale || I18n.locale) do
      Time.use_zone(Rails.configuration.app.dig!(:restaurant_location_time_zone)) do
        block.call
      end
    end
  end

  private

  # Overwrite this method in your mailer to provide a custom locale from params or some record.
  def detect_locale
    return nil if params.blank?
    return nil if params[:locale].blank?

    params[:locale]
  end

  def detect_record
    return nil if params.blank?
    return nil if params[:record].blank?

    params[:record]
  end
end
