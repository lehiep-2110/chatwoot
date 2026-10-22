require 'rails_helper'

RSpec.describe 'Campaigns API', type: :request do
  let(:account) { create(:account) }
  let(:outsider) { create(:user, account: create(:account), role: :administrator) }

  describe 'POST /api/v1/accounts/{account.id}/campaigns' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/campaigns",
             params: { inbox_id: inbox.id, title: 'test', message: 'test message' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        post "/api/v1/accounts/#{account.id}/campaigns",
             params: { inbox_id: inbox.id, title: 'test', message: 'test message' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects creation without adding campaigns, conversations, messages or jobs' do
        headers = administrator.create_new_auth_token
        params = { inbox_id: inbox.id, title: 'test', message: 'test message' }

        expect do
          post "/api/v1/accounts/#{account.id}/campaigns", params: params, headers: headers, as: :json
        end.not_to(change { [Campaign.count, Conversation.count, Message.count, enqueued_jobs.size] })

        expect(response).to have_http_status(:gone)
      end

      it 'rejects creation of an ongoing campaign' do
        headers = administrator.create_new_auth_token
        params = { inbox_id: inbox.id, title: 'test', message: 'test message', trigger_rules: { url: 'https://test.com' } }

        expect do
          post "/api/v1/accounts/#{account.id}/campaigns", params: params, headers: headers, as: :json
        end.not_to change(Campaign, :count)

        expect(response).to have_http_status(:gone)
      end

      it 'returns gone before campaign parameter validation' do
        post "/api/v1/accounts/#{account.id}/campaigns",
             params: { inbox_id: inbox.id, title: 'test', message: 'test message', trigger_rules: { url: 'javascript' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:gone)
      end

      it 'rejects creation of a scheduled one-off campaign' do
        twilio_sms = create(:channel_twilio_sms, account: account)
        twilio_inbox = create(:inbox, channel: twilio_sms, account: account)
        label1 = create(:label, account: account)
        label2 = create(:label, account: account)
        headers = administrator.create_new_auth_token
        params = { inbox_id: twilio_inbox.id, title: 'test', message: 'test message', scheduled_at: 2.days.from_now,
                   audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }] }

        expect do
          post "/api/v1/accounts/#{account.id}/campaigns", params: params, headers: headers, as: :json
        end.not_to(change { [Campaign.count, enqueued_jobs.size] })

        expect(response).to have_http_status(:gone)
      end

      it 'returns gone when campaign parameters are omitted' do
        post "/api/v1/accounts/#{account.id}/campaigns", headers: administrator.create_new_auth_token, as: :json

        expect(response).to have_http_status(:gone)
      end

      it 'rejects an administrator from another account' do
        headers = outsider.create_new_auth_token
        params = { inbox_id: inbox.id, title: 'test', message: 'test message' }

        expect do
          post "/api/v1/accounts/#{account.id}/campaigns", params: params, headers: headers, as: :json
        end.not_to change(Campaign, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/campaigns/:id' do
    let(:inbox) { create(:inbox, account: account) }
    let!(:campaign) { create(:campaign, account: account, trigger_rules: { url: 'https://test.com' }) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}",
              params: { inbox_id: inbox.id, title: 'test', message: 'test message' },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        patch "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}",
              params: { inbox_id: inbox.id, title: 'test', message: 'test message' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      %i[patch put].each do |method|
        it "rejects #{method} without changing the campaign or enqueuing jobs" do
          headers = administrator.create_new_auth_token
          params = { title: 'changed title', message: 'changed message', enabled: false }

          expect do
            public_send(method, "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}", params: params, headers: headers, as: :json)
          end.not_to(change { [campaign.reload.attributes, enqueued_jobs.size] })

          expect(response).to have_http_status(:gone)
        end
      end

      it 'rejects an administrator from another account without changing the campaign' do
        headers = outsider.create_new_auth_token

        expect do
          patch "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}", params: { title: 'changed title' }, headers: headers, as: :json
        end.not_to(change { campaign.reload.attributes })

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/campaigns/:id' do
    let(:inbox) { create(:inbox, account: account) }
    let!(:campaign) { create(:campaign, account: account, trigger_rules: { url: 'https://test.com' }) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'return unauthorized if agent' do
        delete "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects deletion without changing the campaign or its historical conversation' do
        conversation = create(:conversation, account: account, inbox: campaign.inbox, campaign: campaign)
        headers = administrator.create_new_auth_token

        expect do
          delete "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}", headers: headers, as: :json
        end.not_to(change { [Campaign.count, campaign.reload.attributes, conversation.reload.campaign_id, enqueued_jobs.size] })

        expect(response).to have_http_status(:gone)
      end

      it 'rejects an administrator from another account without deleting the campaign' do
        headers = outsider.create_new_auth_token

        expect do
          delete "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}", headers: headers, as: :json
        end.not_to change(Campaign, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
