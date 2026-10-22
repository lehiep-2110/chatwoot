require 'rails_helper'
describe AsyncDispatcher do
  subject(:dispatcher) { described_class.new }

  let!(:conversation) { create(:conversation) }
  let(:event_name) { 'conversation.created' }
  let(:timestamp) { Time.zone.now }
  let(:event_data) { { conversation: conversation } }

  it 'does not register the retired Reports listener' do
    expect(dispatcher.listeners.map { |listener| listener.class.name }).not_to include('ReportingEventListener')
  end

  it 'retains messaging and Automation listeners' do
    expect(dispatcher.listeners).to include(AutomationRuleListener.instance, WebhookListener.instance, NotificationListener.instance)
  end

  it 'does not create report events or rollups when messaging events are published' do
    message = create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox, message_type: :outgoing)
    dispatcher.load_listeners

    expect do
      dispatcher.publish_event('first.reply.created', timestamp, message: message)
      dispatcher.publish_event('reply.created', timestamp, message: message, waiting_since: conversation.created_at)
      dispatcher.publish_event('conversation.resolved', timestamp, conversation: conversation)
    end.not_to(change { [ReportingEvent.count, ReportingEventsRollup.count] })
  end

  describe '#dispatch' do
    it 'enqueue job to dispatch event' do
      expect(EventDispatcherJob).to receive(:perform_later).with(event_name, timestamp, event_data).once
      dispatcher.dispatch(event_name, timestamp, event_data)
    end
  end
end
