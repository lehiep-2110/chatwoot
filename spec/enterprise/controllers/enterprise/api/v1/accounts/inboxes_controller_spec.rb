require 'rails_helper'

RSpec.describe 'Enterprise Inboxes API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  it 'creates a Website inbox with auto assignment configuration' do
    post "/api/v1/accounts/#{account.id}/inboxes",
         headers: admin.create_new_auth_token,
         params: { name: 'HR', auto_assignment_config: { max_assignment_limit: 10 },
                   channel: { type: 'web_widget', website_url: 'example.com' } }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('auto_assignment_config', 'max_assignment_limit')).to eq(10)
  end

  it 'rejects new voice inboxes even with the old feature enabled' do
    account.enable_features!('channel_voice')
    headers = admin.create_new_auth_token
    expect(Twilio::REST::Client).not_to receive(:new)

    expect do
      post "/api/v1/accounts/#{account.id}/inboxes",
           headers: headers,
           params: { name: 'Retired', channel: { type: 'voice', phone_number: '+15551234567' } }, as: :json
    end.not_to(change { [Inbox.count, Channel::TwilioSms.count, enqueued_jobs.size] })

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'reads a legacy voice inbox without advertising call capability or changing credentials' do
    channel = create(:channel_twilio_sms, :with_voice, account: account)
    attributes = channel.reload.attributes

    get "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}", headers: admin.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      'voice_enabled' => false, 'voice_configured' => false,
      'voice_call_webhook_url' => nil, 'voice_status_webhook_url' => nil
    )
    expect(channel.reload.attributes).to eq(attributes)
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inboxes/:id' do
    let(:inbox) { create(:inbox, account: account, auto_assignment_config: { max_assignment_limit: 5 }) }

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) { { name: 'new test inbox', auto_assignment_config: { max_assignment_limit: 10 } } }

      it 'updates inbox with auto assignment config' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['auto_assignment_config']['max_assignment_limit']).to eq 10
      end
    end
  end
end
