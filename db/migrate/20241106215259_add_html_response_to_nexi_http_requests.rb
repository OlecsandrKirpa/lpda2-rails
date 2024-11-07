# frozen_string_literal: true

class AddHtmlResponseToNexiHttpRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :nexi_http_requests, :html_response, :text
  end
end
