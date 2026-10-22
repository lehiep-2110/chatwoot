require 'rails_helper'

RSpec.describe 'Retired Campaign analytics API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:campaign, account: account, inbox: inbox, campaign_type: :one_off, scheduled_at: 1.hour.ago) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let!(:recipient) do
    CampaignRecipient.create!(account: account, campaign: campaign, inbox: inbox, contact: contact,
                              status: :read, source_id: 'wamid.read')
  end

  before { account.enable_features!(:whatsapp_campaign) }

  %w[metrics contacts].each do |endpoint|
    it "returns not found for #{endpoint} even with an authorized administrator and the feature enabled" do
      headers = administrator.create_new_auth_token
      historical_attributes = [campaign.reload.attributes, recipient.reload.attributes]

      expect do
        get "/api/v1/accounts/#{account.id}/campaigns/#{campaign.display_id}/analytics/#{endpoint}", headers: headers, as: :json
      end.not_to(change { [Campaign.count, CampaignRecipient.count, Conversation.count, Message.count, enqueued_jobs.size] })

      expect(response).to have_http_status(:not_found)
      expect([campaign.reload.attributes, recipient.reload.attributes]).to eq(historical_attributes)
    end
  end
end
