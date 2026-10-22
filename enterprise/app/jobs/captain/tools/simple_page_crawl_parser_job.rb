class Captain::Tools::SimplePageCrawlParserJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(assistant_id:, page_link:); end
end
