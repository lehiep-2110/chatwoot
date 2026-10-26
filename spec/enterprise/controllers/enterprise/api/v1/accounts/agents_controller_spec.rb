require 'rails_helper'

RSpec.describe 'Agents API after custom role configuration retirement', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }

  [true, false].each do |feature_enabled|
    context "when the historical custom_roles feature flag is #{feature_enabled}" do
      before { account.enable_features!('custom_roles') if feature_enabled }

      it 'creates a native agent without assigning the retired custom role parameter' do
        post "/api/v1/accounts/#{account.id}/agents",
             headers: admin.create_new_auth_token,
             params: { name: 'New HR', email: 'new-hr@example.test', role: 'agent', custom_role_id: custom_role.id },
             as: :json

        expect(response).to have_http_status(:success)
        membership = account.account_users.find_by!(user: User.from_email('new-hr@example.test'))
        expect(membership.role).to eq('agent')
        expect(membership.custom_role_id).to be_nil
        expect(membership.permissions).to eq(['agent'])
      end

      it 'ignores a custom role assignment while updating an ordinary agent profile' do
        patch "/api/v1/accounts/#{account.id}/agents/#{agent.id}",
              headers: admin.create_new_auth_token,
              params: { name: 'Updated HR', custom_role_id: custom_role.id },
              as: :json

        expect(response).to have_http_status(:success)
        expect(agent.reload.name).to eq('Updated HR')
        expect(agent.account_users.find_by!(account: account).custom_role_id).to be_nil
      end

      it 'preserves historical custom permissions when updating a profile with a clearing parameter' do
        membership = agent.account_users.find_by!(account: account)
        membership.update!(custom_role: custom_role)

        patch "/api/v1/accounts/#{account.id}/agents/#{agent.id}",
              headers: admin.create_new_auth_token,
              params: { name: 'Updated HR', custom_role_id: nil, availability: 'busy' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(membership.reload.custom_role_id).to eq(custom_role.id)
        expect(membership.permissions).to eq(%w[conversation_participating_manage custom_role])
        expect(membership.availability).to eq('busy')
      end
    end
  end

  it 'keeps the administrator able to change a native role' do
    patch "/api/v1/accounts/#{account.id}/agents/#{agent.id}",
          headers: admin.create_new_auth_token,
          params: { role: 'administrator' },
          as: :json

    expect(response).to have_http_status(:success)
    expect(agent.account_users.find_by!(account: account).role).to eq('administrator')
  end

  it 'forbids an ordinary agent from managing other agents' do
    patch "/api/v1/accounts/#{account.id}/agents/#{admin.id}",
          headers: agent.create_new_auth_token,
          params: { role: 'agent', name: 'Unauthorized edit' },
          as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(admin.reload.name).not_to eq('Unauthorized edit')
    expect(admin.account_users.find_by!(account: account).role).to eq('administrator')
  end

  it 'does not replace an existing custom role through the native agents endpoint' do
    membership = agent.account_users.find_by!(account: account)
    membership.update!(custom_role: custom_role)
    replacement = create(:custom_role, account: account, permissions: ['conversation_manage'])

    patch "/api/v1/accounts/#{account.id}/agents/#{agent.id}",
          headers: admin.create_new_auth_token,
          params: { name: 'Updated HR', custom_role_id: replacement.id },
          as: :json

    expect(response).to have_http_status(:success)
    expect(membership.reload.custom_role_id).to eq(custom_role.id)
  end
end
