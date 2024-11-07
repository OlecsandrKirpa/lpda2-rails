# frozen_string_literal: true

class RemoveNotNullConstraintFromNexiHttpRequests < ActiveRecord::Migration[7.0]
  def change
    change_column_null :nexi_http_requests, :response_body, true
  end
end
