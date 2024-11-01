# frozen_string_literal: true

# Key-value store for contact information.
# Example:
# Contact[:email] => "info@example.com"
class Contact < ApplicationRecord
  PUBLIC_KEYS = DEFAULTS.keys.map(&:to_s)

  enum value_type: {
    text: "text"
  }

  # ################################
  # Validations
  # ################################
  validates_with KeyValueValidator
  validates :key, presence: true, uniqueness: { case_sensitive: false }, inclusion: { in: DEFAULTS.keys.map(&:to_s) + DEFAULTS.keys.map(&:to_sym) }
  validates :value_type, presence: true
  validates :value, presence: true, if: -> { DEFAULTS.dig(key.to_sym, :required) == true }

  # ##############################
  # Class methods
  # ##############################
  class << self
    def all_hash
      all_list.map { |item| [item[:key], item] }.to_h.with_indifferent_access
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

    def default(key)
      DEFAULTS.dig(key, :value)
    end

    def [](key)
      where(key:).first&.value || default(key)
    end

    def create_missing
      DEFAULTS.each do |key, data|
        where(key:).first_or_create!(data.as_json(only: %i[value]).merge(key: key))
      end
    end
  end

  # ##############################
  # Instance methods
  # ##############################
end
