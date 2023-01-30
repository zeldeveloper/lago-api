# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  sidekiq_options retry: 0

  private

  def wait_algorithm(executions)
    # NOTE: This is based on the Rails Active Job wait algorithm
    ((executions**4) + (Kernel.rand * (executions**4) * jitter)) + 2
  end
end
