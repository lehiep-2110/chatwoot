class Captain::Documents::ResponseBuilderJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(document, options = {}); end
end
