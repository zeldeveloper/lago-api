# frozen_string_literal: true

module Clock
  class VersionsCleanupJob < ApplicationJob
    queue_as 'clock'

    def perform
      binding.break
      PaperTrail::Version.where('created_at < ?', 90.days.ago).delete_all
    end
  end
end
