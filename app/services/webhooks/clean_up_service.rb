# frozen_string_literal: true

module Webhooks
  class CleanUpService
    def self.call(...)
      new(...).call
    end

    def call
      Webhooks.where('updated_at > ?', Time.zone.now + 90.days).destroy_all
    end
  end
end
