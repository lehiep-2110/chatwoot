require 'rails_helper'

RSpec.describe 'Retired Calls routes', type: :routing do
  paths = [
    [:get, '/api/v1/accounts/1/calls'], [:post, '/api/v1/accounts/1/contacts/2/call'],
    [:get, '/api/v1/accounts/1/whatsapp_calls/2'], [:post, '/api/v1/accounts/1/whatsapp_calls/initiate'],
    [:post, '/api/v1/accounts/1/inboxes/2/conference'], [:delete, '/api/v1/accounts/1/inboxes/2/conference'],
    [:get, '/api/v1/accounts/1/inboxes/2/conference/token'],
    [:post, '/api/v1/accounts/1/integrations/dyte/create_a_meeting'],
    [:post, '/api/v1/accounts/1/integrations/dyte/add_participant_to_meeting'],
    [:post, '/api/v1/widget/integrations/dyte/add_participant_to_meeting']
  ]
  %w[accept reject terminate upload_recording].each do |action|
    paths << [:post, "/api/v1/accounts/1/whatsapp_calls/2/#{action}"]
  end
  %w[enable_whatsapp_calling disable_whatsapp_calling set_inbound_calls set_call_recording].each do |action|
    paths << [:post, "/api/v1/accounts/1/inboxes/2/#{action}"]
  end
  %w[call status conference_status recording_status].each do |action|
    paths << [:post, "/twilio/voice/#{action}/15551234567"]
  end

  paths.each do |method, path|
    it "does not route #{method.upcase} #{path}" do
      expect(method => path).not_to be_routable
    end
  end

  it 'retains Twilio SMS callbacks' do
    expect(post: '/twilio/callback').to route_to(controller: 'twilio/callback', action: 'create')
  end

  it 'retains Website messages' do
    expect(get: '/api/v1/widget/messages').to route_to(controller: 'api/v1/widget/messages', action: 'index', format: 'json')
  end
end
