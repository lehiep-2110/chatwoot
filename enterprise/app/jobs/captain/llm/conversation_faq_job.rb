class Captain::Llm::ConversationFaqJob < MutexApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(conversation, assistant); end
end
