require 'rails_helper'

RSpec.describe 'Retired Captain API routes', type: :routing do
  it 'has no Captain controller entry points' do
    controllers = Rails.application.routes.routes.map { |route| route.defaults[:controller].to_s }
    expect(controllers.grep(%r{/captain/})).to be_empty
  end

  paths = [
    [:get, '/api/v1/accounts/1/captain/preferences'], [:patch, '/api/v1/accounts/1/captain/preferences'],
    [:get, '/api/v1/accounts/1/captain/assistants'], [:post, '/api/v1/accounts/1/captain/assistants'],
    [:get, '/api/v1/accounts/1/captain/documents'], [:post, '/api/v1/accounts/1/captain/documents'],
    [:delete, '/api/v1/accounts/1/captain/documents/2'], [:post, '/api/v1/accounts/1/captain/documents/2/sync'],
    [:get, '/api/v1/accounts/1/captain/copilot_threads'], [:post, '/api/v1/accounts/1/captain/copilot_threads'],
    [:post, '/api/v1/accounts/1/captain/copilot_threads/2/copilot_messages'],
    [:get, '/api/v1/accounts/1/conversations/2/inbox_assistant'],
    [:post, '/api/v1/accounts/1/inboxes/2/csat_template/analyze'], [:post, '/enterprise/webhooks/firecrawl']
  ]
  %w[rewrite summarize reply_suggestion label_suggestion follow_up].each do |action|
    paths << [:post, "/api/v1/accounts/1/captain/tasks/#{action}"]
  end
  paths.each do |method, path|
    it "does not route #{method.upcase} #{path}" do
      expect(method => path).not_to be_routable
    end
  end

  it 'retains the external AgentBot assignment route' do
    expect(post: '/api/v1/accounts/1/conversations/2/assignments').to route_to(
      controller: 'api/v1/accounts/conversations/assignments', action: 'create', account_id: '1', conversation_id: '2', format: 'json'
    )
  end
end
