# frozen_string_literal: true

require 'lago_http_client'

module Webhooks
  # NOTE: Abstract Service, should not be used directly
  class BaseService
    def initialize(object:, options: {}, webhook_id: nil)
      @object = object
      @options = options&.with_indifferent_access
      @webhook_id = webhook_id
    end

    def call
      return unless current_organization&.webhook_url?

      webhook = Webhook.find_or_initialize_by(
        id: webhook_id,
        webhook_type:,
        object_id: object&.id,
        object_type: object&.class,
        endpoint: current_organization.webhook_url,
      )

      payload = {
        webhook_type:,
        object_type:,
        object_type => object_serializer.serialize,
      }

      webhook.payload = payload.to_json
      webhook.attempts += 1
      webhook.retried_at = DateTime.zone.now unless webhook.attempts == 1
      webhook.save

      http_client = LagoHttpClient::Client.new(current_organization.webhook_url)
      headers = generate_headers(payload)
      response = http_client.post(payload, headers)

      webhook.http_status = response.status.to_i
      webhook.response = response.to_json
      webhook.succeeded!
    rescue LagoHttpClient::HttpError => e
      return if webhook.attempts == 3

      webhook.response = e.message
      webhook.failed!

      SendWebhookJob.perform_later(webhook_type, object, options, webhook.id)
    end

    private

    attr_reader :object, :options, :webhook_id

    def object_serializer
      # Empty
    end

    def current_organization
      # Empty
    end

    def webhook_type
      # Empty
    end

    def object_type
      # Empty
    end

    def generate_headers(payload)
      [
        'X-Lago-Signature' => generate_signature(payload),
      ]
    end

    def generate_signature(payload)
      JWT.encode(
        {
          data: payload.to_json,
          iss: issuer,
        },
        RsaPrivateKey,
        'RS256',
      )
    end

    def issuer
      ENV['LAGO_API_URL']
    end
  end
end
