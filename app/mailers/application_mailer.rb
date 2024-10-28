# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Config.app.dig(:emails, :default_from),
          reply_to: Config.app.dig(:emails, :default_reply_to) || Config.app.dig(:emails, :default_from)

  layout "mailer"

  before_action do
    headers "X-ApplicationSender" => "lpda2"

    locale = detect_locale
    if locale
      @locale_was = I18n.locale
      I18n.locale = locale
    else
      @locale_was = nil
    end

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

    @contacts = Setting[:email_contacts]
  end

  after_action do
    if @locale_was
      I18n.locale = @locale_was
    end

    delivered_email = params[:delivered_email] || Log::DeliveredEmail.find_by(id: params[:delivered_email_id]) || Log::DeliveredEmail.create!

    delivered_email.update!(
      {
        text: mail.text_part&.body&.decoded,
        html: mail.html_part&.body&.decoded,
        subject: mail.subject,
        headers: mail.header.fields.map { |field| [field.name, field.value] }.to_h,
        raw: mail.to_s,
        record: detect_record,
      }.compact
    )
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
