require 'rails_helper'

RSpec.describe 'Retired Enterprise Reports API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }

  it 'returns not found for an administrator' do
    get "/api/v2/accounts/#{account.id}/reports", headers: administrator.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  it 'does not restore access for a custom report role' do
    agent.account_users.find_by!(account: account).update!(custom_role: custom_role)
    get "/api/v2/accounts/#{account.id}/reports/drilldown", headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
