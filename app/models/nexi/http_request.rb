# frozen_string_literal: true

module Nexi
  # Traking HTTP requests to nexi API.
  class HttpRequest < ApplicationRecord
    # ###################################
    # Validations
    # ###################################
    validates :request_body,
              :url,
              :http_code,
              :http_method,
              :started_at,
              :ended_at, presence: true

    # ###################################
    # Associations
    # ###################################
    belongs_to :record, polymorphic: true, optional: true

    # ###################################
    # Instance methods
    # ###################################

    def time
      (ended_at - started_at).to_f
    end
  end
end
