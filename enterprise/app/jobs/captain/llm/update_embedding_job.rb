class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(record, content); end
end
