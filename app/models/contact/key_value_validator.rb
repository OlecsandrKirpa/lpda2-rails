# frozen_string_literal: true

class Contact
  class KeyValueValidator < ActiveModel::Validator
    attr_accessor :record

    def validate(record)
      @record = record
      return unless can_run?

      case record.key.to_sym
      when :email then validate_email
      when :phone then validate_phone
      when :whatsapp_number then validate_phone
      when :facebook_url then validate_facebook_url
      when :instagram_url then validate_instagram_url
      when :tripadvisor_url then validate_tripadvisor_url
      when :homepage_url then validate_homepage_url
      when :google_url then validate_google_url
      else
        Rails.logger.warn("Don't know how to validate key: #{record.key.to_s.inspect}")
      end
    end

    private

    def can_run?
      return false if record.key.to_s.blank?
      return false if record.value.blank?

      unless [String, Symbol].include?(record.key.class)
        record.errors.add(:value, "should be a string or symbol. got #{record.key.class.inspect}")
        return false
      end

      true
    end

    def validate_email
      return if record.value.is_a?(String) && record.value.match?(URI::MailTo::EMAIL_REGEXP)

      record.errors.add(:value, "invalid email, got #{record.value.inspect}")
    end

    def validate_phone
      return if record.value.is_a?(String) && record.value.match?(/\A\+?[0-9\s]+\z/)

      record.errors.add(:value, "invalid phone number, got #{record.value.inspect}")
    end

    def validate_facebook_url
      validate_url
      return if record.value.is_a?(String) && record.value.starts_with?("https://www.facebook.com/")

      record.errors.add(:value, "invalid facebook url, got #{record.value.inspect}")
    end

    def validate_instagram_url
      validate_url
      return if record.value.is_a?(String) && record.value.starts_with?("https://www.instagram.com/")

      record.errors.add(:value, "invalid instagram url, got #{record.value.inspect}")
    end

    def validate_tripadvisor_url
      validate_url
      return if record.value.is_a?(String) && record.value.starts_with?("https://www.tripadvisor.")

      record.errors.add(:value, "invalid tripadvisor url, got #{record.value.inspect}")
    end

    def validate_homepage_url
      validate_url
    end

    def validate_google_url
      validate_url

      return if record.value.is_a?(String) && record.value.starts_with?("https://g.page/")

      record.errors.add(:value, "invalid google url, got #{record.value.inspect}")
    end

    def validate_url
      return if record.value.is_a?(String) && record.value.match?(URI::DEFAULT_PARSER.make_regexp)

      record.errors.add(:value, "invalid url, got #{record.value.inspect}")
    end
  end
end
