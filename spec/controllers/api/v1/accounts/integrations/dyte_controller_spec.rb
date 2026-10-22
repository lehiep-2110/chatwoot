require 'rails_helper'

RSpec.describe 'Retired Calls integration settings', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let!(:hook) do
    create(:integrations_hook, app_id: 'dyte', account: account, status: :disabled,
                               settings: { account_id: 'historical', app_id: 'historical', api_token: 'historical-token' })
  end

  it 'hides the integration catalog entry and direct lookup' do
    get "/api/v1/accounts/#{account.id}/integrations/apps", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('"id":"dyte"')

    get "/api/v1/accounts/#{account.id}/integrations/apps/dyte", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'rejects creation before validating remote credentials' do
    expect(HTTParty).not_to receive(:get)
    expect do
      post "/api/v1/accounts/#{account.id}/integrations/hooks",
           headers: headers,
           params: { hook: { app_id: 'dyte', settings: {} } }, as: :json
    end.not_to change(Integrations::Hook, :count)
    expect(response).to have_http_status(:gone)
  end

  it 'rejects updates and events without altering a historical hook' do
    attributes = hook.reload.attributes
    patch "/api/v1/accounts/#{account.id}/integrations/hooks/#{hook.id}",
          headers: headers,
          params: { hook: { status: 'enabled', settings: {} } }, as: :json
    expect(response).to have_http_status(:gone)

    post "/api/v1/accounts/#{account.id}/integrations/hooks/#{hook.id}/process_event", headers: headers, as: :json
    expect(response).to have_http_status(:gone)
    expect(hook.reload.attributes).to eq(attributes)
  end
end
