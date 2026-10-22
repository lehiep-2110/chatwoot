require 'rails_helper'

RSpec.describe 'Retired Help Center API history', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:portal) { create(:portal, account: account) }
  let!(:article) { create(:article, portal: portal, account: account, author: admin) }

  it 'returns not found without changing historical content' do
    attributes = [portal.reload.attributes, article.reload.attributes]
    get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
    expect([portal.reload.attributes, article.reload.attributes]).to eq(attributes)
  end
end
