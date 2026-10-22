require 'rails_helper'

RSpec.describe EventDispatcherJob do
  subject(:job) { described_class.perform_later(event_name, timestamp, event_data) }

  let!(:conversation) { create(:conversation) }
  let(:event_name) { 'conversation.created' }
  let(:timestamp) { Time.zone.now }
  let(:event_data) { { conversation: conversation } }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(event_name, timestamp, event_data)
      .on_queue('critical')
  end

  it 'publishes event' do
    expect(Rails.configuration.dispatcher.async_dispatcher).to receive(:publish_event).with(event_name, timestamp, event_data).once
    event_dispatcher = described_class.new
    event_dispatcher.perform(event_name, timestamp, event_data)
  end

  it 'continues delivering message events to automation and webhooks' do
    message = create(:message, conversation: conversation)
    expect(AutomationRuleListener.instance).to receive(:message_created).with(an_instance_of(Events::Base)).once
    expect(WebhookListener.instance).to receive(:message_created).with(an_instance_of(Events::Base)).once

    described_class.perform_now(Events::Types::MESSAGE_CREATED, timestamp, message: message)
  end

  context 'when processing a legacy campaign event' do
    let(:inbox) { conversation.inbox }
    let(:contact) { create(:contact, account: inbox.account) }
    let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact) }
    let(:campaign) { create(:campaign, inbox: inbox, account: inbox.account) }
    let(:campaign_data) { { contact_inbox: contact_inbox, event_info: { campaign_id: campaign.reload.display_id } } }

    %w[campaign.triggered campaign_triggered].each do |event_name|
      it "ignores #{event_name} without creating a conversation or message" do
        data = campaign_data

        expect do
          described_class.perform_now(event_name, timestamp, data)
        end.not_to(change { [Conversation.count, Message.count] })
      end
    end
  end
end
