class CreateNexiOrderOutcomeRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :nexi_order_outcome_requests do |t|
      t.jsonb :body
      t.jsonb :headers

      t.timestamps
    end
  end
end
