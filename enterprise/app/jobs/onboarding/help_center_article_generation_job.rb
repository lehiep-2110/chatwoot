class Onboarding::HelpCenterArticleGenerationJob < ApplicationJob
  queue_as :low

  # Consume jobs queued before Captain retirement without AI calls or changes to historical data.
  def perform(account_id, portal_id, user_id, generation_id); end
end
