require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let(:conversation) { create(:conversation) }

  it 'does not calculate or publish SLA data even when the reserved flag is enabled' do
    conversation.account.enable_features!('sla')
    conversation.update!(sla_policy_id: create(:sla_policy, account: conversation.account).id)

    payload = described_class.new(conversation).push_data

    expect(payload.keys).not_to include(:applied_sla, :sla_events, :sla_policy_id)
    expect(payload).to include(id: conversation.display_id, inbox_id: conversation.inbox_id, status: conversation.status)
  end
end
