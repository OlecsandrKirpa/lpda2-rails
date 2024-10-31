# frozen_string_literal: true

class AddControllerPathAndActionNameToLogDeliveredEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :log_delivered_emails, :controller_path, :text
    add_column :log_delivered_emails, :action_name, :text
  end
end
