require 'rails_helper'

RSpec.describe 'Enterprise Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:policy) { create(:sla_policy, account: account) }

  before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

  [true, false].each do |enabled|
    it "ignores retired SLA assignment when the reserved feature flag is #{enabled}" do
      account.enable_features!('sla') if enabled
      account.disable_features!('sla') unless enabled

      patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            params: { sla_policy_id: policy.id, priority: 'high' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(conversation.reload).to have_attributes(sla_policy_id: nil, priority: 'high')
      expect(conversation.applied_sla).to be_nil
      expect(response.parsed_body['sla_policy_id']).to be_nil
    end
  end

  it 'keeps historical assignments while updating supported conversation fields' do
    conversation.update!(sla_policy_id: policy.id)

    patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
          params: { sla_policy_id: create(:sla_policy, account: account).id, priority: 'high' },
          headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(conversation.reload).to have_attributes(sla_policy_id: policy.id, priority: 'high')
    expect(conversation.applied_sla).to be_nil
    expect(response.parsed_body.keys).not_to include('applied_sla', 'sla_events')
  end
end
