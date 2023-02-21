# frozen_string_literal: true

require 'rails_helper'

describe Clock::VersionsCleanupJob, job: true do
  subject(:versions_cleanup_job) { described_class }

  describe '.perform' do
    it 'removes all old versions', versioning: true do
      plan = create(:plan)

      expect { versions_cleanup_job.perform_now }
        .to change { plan.reload.versions.count }.from(1).to(0)
        .and change { plan.organization.versions.count }.from(1).to(0)
    end
  end
end
