require 'rails_helper'

RSpec.describe 'Dashboard after Help Center retirement', type: :request do
  let!(:portal) { create(:portal, custom_domain: 'retired.example.com', config: { default_locale: 'fr' }) }

  it 'does not render the portal on its old custom domain' do
    expect(Portal).not_to receive(:find_by)
    get '/', headers: { 'HOST' => portal.custom_domain }

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('chatwoot-help-center')
  end

  it 'returns not found for the old public path without changing historical content' do
    attributes = portal.reload.attributes
    get "/hc/#{portal.slug}/fr"

    expect(response).to have_http_status(:not_found)
    expect(portal.reload.attributes).to eq(attributes)
  end
end
