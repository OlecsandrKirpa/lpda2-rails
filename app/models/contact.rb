# frozen_string_literal: true

# Key-value store for contact information.
# Example:
# Contact[:email] => "info@example.com"
class Contact < ApplicationRecord
  enum value_type: {
    text: "text"
  }

  # ################################
  # Validations
  # ################################
  validates_with KeyValueValidator
  validates :key, presence: true, uniqueness: { case_sensitive: false },
                  inclusion: { in: DEFAULTS.keys.map(&:to_s) + DEFAULTS.keys.map(&:to_sym) }
  validates :value_type, presence: true
  validates :value, presence: true, if: -> { DEFAULTS.dig(key.to_sym, :required) == true }

  # ##############################
  # Callbacks
  # ##############################
  before_validation :strip_value_if_needed
  before_validation :remove_whitespaces_if_needed

  # ##############################
  # Class methods
  # ##############################
  class << self
    def all_hash
      all_list.index_by { |item| item[:key] }.with_indifferent_access
    end

    def all_list
      [
        all.pluck(:key),
        DEFAULTS.keys
      ].flatten.map(&:to_sym).uniq.map do |key|
        {
          key:,
          value: self[key]
        }
      end
    end

    def public_formatted
      additions = {
        whatsapp_url: self[:whatsapp_number].present? ? "https://wa.me/#{self[:whatsapp_number]}" : nil
      }.compact

      all_hash.transform_values { |i| i[:value] }.merge(additions).with_indifferent_access
    end

    def default(key)
      DEFAULTS.dig(key, :value)
    end

    def [](key)
      (f = find_by(key:)).present? ? f.value : default(key)
    end

    def create_missing
      DEFAULTS.each do |key, data|
        where(key:).first_or_create!(data.as_json(only: %i[value]).merge(key:))
      end
    end
  end

  # ##############################
  # Instance methods
  # ##############################

  def strip_value_if_needed
    return if value.blank? || key.blank? || DEFAULTS.dig(key.to_sym, :strip) != true

    self.value = value.strip
  end

  def remove_whitespaces_if_needed
    return if value.blank? || key.blank? || DEFAULTS.dig(key.to_sym, :remove_whitespaces) != true

    self.value = value.delete(" ").delete("\t").delete("\n").delete("\r")
  end
end
