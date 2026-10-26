require 'rails_helper'

RSpec.describe AppliedSla do
  let(:conversation) { create(:conversation) }
  let(:account) { conversation.account }
  let(:policy) { create(:sla_policy, account: account) }

  it 'preserves historical SLA rows and messages while conversations are resolved and reopened' do
    conversation.update!(sla_policy_id: policy.id)
    applied = create(:applied_sla, conversation: conversation, account: account, sla_policy: policy, completed_at: 1.day.ago)
    event = create(:sla_event, conversation: conversation, applied_sla: applied, sla_policy: policy, account: account)
    message = create(:message, conversation: conversation, account: account)
    snapshot = applied.attributes
    event_snapshot = event.attributes

    expect do
      conversation.update!(status: :resolved)
      conversation.update!(status: :open)
    end.not_to(change { [described_class.count, SlaEvent.count, Notification.where(notification_type: [6, 7, 8]).count] })

    expect(applied.reload.attributes).to eq(snapshot)
    expect(event.reload.attributes).to eq(event_snapshot)
    expect(conversation.messages.find(message.id)).to eq(message)
  end

  it 'does not generate notifications from historical breach records' do
    applied = create(:applied_sla, conversation: conversation, account: account, sla_policy: policy)

    expect do
      create(:sla_event, conversation: conversation, applied_sla: applied, sla_policy: policy, account: account)
    end.not_to change(Notification, :count)
  end

  it 'retains the secondary actor of old notifications without delivering email or push' do
    user = create(:user, account: account)
    notification = create(:notification, account: account, user: user, primary_actor: conversation,
                                         secondary_actor: policy, notification_type: :sla_missed_first_response)
    allow(AgentNotifications::ConversationNotificationsMailer).to receive(:with)
    email_service = Notification::EmailNotificationService.new(notification: notification)
    push_service = Notification::PushNotificationService.new(notification: notification)
    allow(Notification::EmailNotificationService).to receive(:new).and_return(email_service)
    allow(Notification::PushNotificationService).to receive(:new).and_return(push_service)
    expect(email_service).not_to receive(:user_subscribed_to_notification?)
    expect(push_service).not_to receive(:user_subscribed_to_notification?)

    expect(notification.push_event_data[:secondary_actor]).to include(id: policy.id, name: policy.name)
    Notification::EmailNotificationJob.perform_now(notification)
    Notification::PushNotificationJob.perform_now(notification)

    expect(AgentNotifications::ConversationNotificationsMailer).not_to have_received(:with)
    expect(notification.reload.notification_type).to eq('sla_missed_first_response')
  end
end
