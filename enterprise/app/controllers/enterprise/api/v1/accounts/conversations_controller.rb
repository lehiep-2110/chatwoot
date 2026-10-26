module Enterprise::Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern

  def reporting_events
    @reporting_events = @conversation.reporting_events.order(created_at: :asc)
  end
end
