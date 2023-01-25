# frozen_string_literal: true

module Clock
  class CleanUpWebhooksJob < ApplicationJob
    queue_as 'clock'

    def perform
      Webhooks::CleanUpService.call
    end
  end
end
