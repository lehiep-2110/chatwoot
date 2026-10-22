require 'rails_helper'

RSpec.describe 'Retired account reporting events API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:reporting_event) do
    create(:reporting_event, account: account, conversation: conversation, inbox: conversation.inbox, user: administrator)
  end

  it 'returns not found without modifying historical events or conversations' do
    headers = administrator.create_new_auth_token
    historical_attributes = reporting_event.reload.attributes

    expect do
      get "/api/v1/accounts/#{account.id}/reporting_events", headers: headers, as: :json
    end.not_to(change { [ReportingEvent.count, ReportingEventsRollup.count, Conversation.count, Message.count] })

    expect(response).to have_http_status(:not_found)
    expect(reporting_event.reload.attributes).to eq(historical_attributes)
  end
end
