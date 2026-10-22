class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as :low

  # Retain the class and argument for jobs queued before Campaigns was retired.
  def perform(_campaign); end
end
