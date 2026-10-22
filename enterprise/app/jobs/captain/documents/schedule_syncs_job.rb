class Captain::Documents::ScheduleSyncsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(plan_name = nil); end
end
