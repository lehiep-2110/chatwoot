module Enterprise::Webhooks::WhatsappEventsJob
  def handle_message_events(channel, params, locked_sender_id = nil)
    # Retired call events must not fall through into the shared messaging processor.
    return if call_event?(params) || call_permission_reply?(params)

    super
  end

  private

  def call_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'calls'
  end

  def call_permission_reply?(params)
    params.dig(:entry, 0, :changes, 0, :value, :messages, 0, :interactive, :type) == 'call_permission_reply'
  end
end
