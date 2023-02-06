# frozen_string_literal: true

class CreateWebhooks < ActiveRecord::Migration[7.0]
  def change
    create_table :webhooks, id: :uuid do |t|
      t.references :organization, index: true

      t.uuid :object_id
      t.string :object_type

      t.integer :retries, default: 0
      t.integer :status, default: 0
      t.integer :http_status

      t.string :webhook_type

      t.string :endpoint
      t.json :payload
      t.json :response

      t.timestamp :retried_at
      t.timestamps
    end
  end
end
