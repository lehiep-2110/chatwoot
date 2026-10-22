class Captain::InboxPendingConversationsResolutionJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(inbox); end
end
