require 'rails_helper'

RSpec.describe 'Retired Campaign read routes', type: :routing do
  [
    '/api/v1/accounts/1/campaigns',
    '/api/v1/accounts/1/campaigns/2',
    '/api/v1/accounts/1/campaigns/2/analytics/metrics',
    '/api/v1/accounts/1/campaigns/2/analytics/contacts',
    '/api/v1/accounts/1/inboxes/2/campaigns',
    '/api/v1/widget/campaigns'
  ].each do |path|
    it "does not route GET #{path}" do
      expect(get: path).not_to be_routable
    end
  end

  it 'retains the conversation list route' do
    expect(get: '/api/v1/accounts/1/conversations').to route_to(
      controller: 'api/v1/accounts/conversations', action: 'index', account_id: '1', format: 'json'
    )
  end

  it 'retains the inbox list route' do
    expect(get: '/api/v1/accounts/1/inboxes').to route_to(
      controller: 'api/v1/accounts/inboxes', action: 'index', account_id: '1', format: 'json'
    )
  end

  it 'retains the Website Widget messages route' do
    expect(get: '/api/v1/widget/messages').to route_to(controller: 'api/v1/widget/messages', action: 'index', format: 'json')
  end
end
