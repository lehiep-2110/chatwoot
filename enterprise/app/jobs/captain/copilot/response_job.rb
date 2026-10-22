class Captain::Copilot::ResponseJob < ApplicationJob
  queue_as :default

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(assistant:, conversation_id:, user_id:, copilot_thread_id:, message:); end
end
