class Enterprise::CloudflareVerificationJob < ApplicationJob
  queue_as :default

  # Consume jobs queued before Help Center was retired without changing historical data.
  def perform(_portal_id); end
end
