# frozen_string_literal: true

class Setting
  class KeyValueValidator < ActiveModel::Validator
    attr_accessor :record

    def validate(record)
      @record = record
      return unless can_run?

      case record.key.to_sym
      when :default_language then validate_default_language
      when :available_locales then validate_available_locales
      when :max_people_per_reservation then validate_max_people_per_reservation
      when :email_images then validate_email_images
      when :reservation_max_days_in_advance then validate_reservation_max_days_in_advance
      when :reservation_min_hours_in_advance then validate_reservation_min_hours_in_advance
      when :cover_price then validate_cover_price
      when :instagram_landing_page_url then validate_instagram_landing_page_url
      when :reservation_min_hours_advance_cancel then validate_reservation_min_hours_advance_cancel
      when :nexi_auto_refund_cancelled_reservations then boolean_validator
      else
        record.errors.add(:key, "Don't know how to validate key: #{record.key.to_s.inspect}")
      end
    end

    private

    def boolean_validator
      return if %w[true false].include?(record.value)

      record.errors.add(:value, "should be 'true' or 'false'. got #{record.value.inspect}")
    end

    def can_run?
      return false if record.key.to_s.blank?
      return false if record.value.nil?

      unless [String, Symbol].include?(record.key.class)
        record.errors.add(:value, "should be a string or symbol. got #{record.key.class.inspect}")
        return false
      end

      true
    end

    def validate_default_language
      return if I18n.available_locales.include?(record.value.to_sym)

      record.errors.add(:value, "#{record.value.to_s.inspect} is not a valid language")
    end

    def validate_available_locales
      return unless record.value.is_a?(Array)
      return if (invalid_locales = record.value.reject { |v| I18n.available_locales.include?(v.to_sym) }).empty?

      # return if record.value.all? { |v| I18n.available_locales.include?(v.to_sym) }

      record.errors.add(:value, "contains invalid languages: #{invalid_locales.join(", ")}")
    end

    def validate_max_people_per_reservation
      return if record.value.to_i.positive?

      record.errors.add(:value, "should be a positive integer")
    end

    def validate_reservation_min_hours_advance_cancel
      return if record.value.to_f >= 0

      record.errors.add(:value,
                        "reservation_min_hours_advance_cancel should be a positive integer, got #{record.value.inspect}")
    end

    def validate_email_images
      return record.errors.add(:value, "should be a Hash, got #{record.value.class}") unless record.value.is_a?(Hash)

      record.value.each_value do |val|
        unless val.is_a?(String) && val.match?(URI::DEFAULT_PARSER.make_regexp)
          record.errors.add(:value,
                            "should be a url, got #{val.class}")
        end
      end
    end

    # def validate_email_contacts
    #   return record.errors.add(:value, "should be a Hash, got #{record.value.class}") unless record.value.is_a?(Hash)

    #   record.value.each_value do |val|
    #     record.errors.add(:value, "should be a string, got #{val.class}") unless val.is_a?(String)
    #   end

    #   mandatory_keys = %w[address email phone whatsapp_number whatsapp_url facebook_url instagram_url tripadvisor_url
    #                       homepage_url google_url]
    #   missing_keys = mandatory_keys - record.value.keys
    #   record.errors.add(:value, "missing keys: #{missing_keys.join(", ")}") if missing_keys.present?

    #   unknown_keys = record.value.keys - mandatory_keys
    #   record.errors.add(:value, "unknown keys: #{unknown_keys.join(", ")}") if unknown_keys.present?
    # end

    def validate_reservation_max_days_in_advance
      return if record.value.to_f.positive? || record.value.to_f.zero?

      record.errors.add(:value, "should be a number >= 0")
    end

    def validate_reservation_min_hours_in_advance
      return if record.value.to_f.positive? || record.value.to_f.zero?

      record.errors.add(:value, "should be a number >= 0")
    end

    def validate_cover_price
      return if record.value.to_f.positive? || record.value.to_f.zero?

      record.errors.add(:value, "expected number >= 0")
    end

    def validate_instagram_landing_page_url
      return if record.value.blank?
      return if record.value.is_a?(String) &&
                record.value.match?(URI::DEFAULT_PARSER.make_regexp) &&
                record.value.include?("instagram.com") &&
                record.value.starts_with?("http")

      record.errors.add(:value,
                        "should be an instagram url, like 'https://www.instagram.com/....', got #{record.value.inspect}")
    end
  end
end
