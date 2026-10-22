require 'rails_helper'

RSpec.describe ActionCableListener do
  it 'does not handle a legacy Copilot event while keeping the shared listener available' do
    expect(described_class.instance).not_to respond_to(:copilot_message_created)
    expect(ActionCableBroadcastJob).not_to receive(:perform_later)

    Rails.configuration.dispatcher.sync_dispatcher.dispatch('copilot.message.created', Time.zone.now, copilot_message: nil)
  end
end
