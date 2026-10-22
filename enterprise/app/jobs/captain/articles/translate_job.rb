class Captain::Articles::TranslateJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(account, article_id, target_locale, target_category_id, user); end
end
