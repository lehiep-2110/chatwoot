class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  queue_as :default

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(conversation, assistant, responding_to_message_id = nil); end
end
