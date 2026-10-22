class Captain::Documents::PerformSyncJob < MutexApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(document); end
end
