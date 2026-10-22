require 'rails_helper'

RSpec.describe Campaigns::TriggerOneoffCampaignJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, account: account) }
  let(:campaign_status) { :active }
  let(:campaign) { create(:campaign, inbox: channel.inbox, account: account, campaign_status: campaign_status) }
  let!(:conversation) { create(:conversation, inbox: channel.inbox, account: account, campaign: campaign) }
  let!(:message) { create(:message, account: account, inbox: channel.inbox, conversation: conversation) }

  shared_examples 'a retired campaign job' do
    it 'consumes a serialized job without sending, enqueueing or changing historical data' do
      campaign_attributes = campaign.reload.attributes
      message_attributes = message.reload.attributes
      serialized_job = JSON.parse(described_class.new(campaign).serialize.to_json)

      expect(Twilio::REST::Client).not_to receive(:new)
      expect(HTTParty).not_to receive(:post)
      expect(Whatsapp::TemplateProcessorService).not_to receive(:new)

      expect do
        described_class.execute(serialized_job)
      end.not_to(change { [Campaign.count, Conversation.count, Message.count, enqueued_jobs.size] })

      expect(campaign.reload.attributes).to eq(campaign_attributes)
      expect(conversation.reload.campaign_id).to eq(campaign.id)
      expect(message.reload.attributes).to eq(message_attributes)
    end
  end

  it 'retains the existing queue contract' do
    expect { described_class.perform_later(campaign) }.to have_enqueued_job(described_class)
      .with(campaign)
      .on_queue('low')
  end

  it 'does not send or change a campaign when called directly' do
    campaign_attributes = campaign.reload.attributes

    expect(Twilio::REST::Client).not_to receive(:new)
    expect(HTTParty).not_to receive(:post)
    expect(Whatsapp::TemplateProcessorService).not_to receive(:new)

    expect do
      described_class.perform_now(campaign)
    end.not_to(change { [Conversation.count, Message.count, enqueued_jobs.size] })

    expect(campaign.reload.attributes).to eq(campaign_attributes)
  end

  context 'with a Twilio SMS campaign' do
    %i[active processing completed].each do |status|
      context "when #{status}" do
        let(:campaign_status) { status }

        it_behaves_like 'a retired campaign job'
      end
    end
  end

  context 'with an SMS campaign' do
    let(:channel) { create(:channel_sms, account: account) }

    it_behaves_like 'a retired campaign job'
  end

  context 'with a WhatsApp campaign' do
    let(:channel) { create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false) }

    it_behaves_like 'a retired campaign job'

    context 'when the WhatsApp campaign feature is enabled' do
      before { account.enable_features!(:whatsapp_campaign) }

      it_behaves_like 'a retired campaign job'
    end
  end

  context 'with a Website campaign' do
    let(:channel) { create(:channel_widget, account: account) }

    it_behaves_like 'a retired campaign job'
  end
end
