require 'rails_helper'

RSpec.describe 'Retired Reports routes', type: :routing do
  paths = ['/api/v2/accounts/1/reports', '/api/v2/accounts/1/year_in_review', '/api/v1/accounts/1/reporting_events']
  paths += %w[summary bot_summary agents inboxes labels teams conversations conversations_summary conversation_traffic
              drilldown bot_metrics inbox_label_matrix first_response_time_distribution outgoing_messages_count].map do |action|
    "/api/v2/accounts/1/reports/#{action}"
  end
  paths += %w[agent team inbox label channel].map { |action| "/api/v2/accounts/1/summary_reports/#{action}" }
  paths += %w[conversation_metrics grouped_conversation_metrics].map { |action| "/api/v2/accounts/1/live_reports/#{action}" }

  paths.each do |path|
    it "does not route GET #{path}" do
      expect(get: path).not_to be_routable
    end
  end

  it 'retains the conversation list' do
    expect(get: '/api/v1/accounts/1/conversations').to route_to(
      controller: 'api/v1/accounts/conversations', action: 'index', account_id: '1', format: 'json'
    )
  end

  it 'retains Website messages' do
    expect(get: '/api/v1/widget/messages').to route_to(controller: 'api/v1/widget/messages', action: 'index', format: 'json')
  end

  it 'retains per-conversation reporting history' do
    expect(get: '/api/v1/accounts/1/conversations/2/reporting_events').to route_to(
      controller: 'api/v1/accounts/conversations', action: 'reporting_events', account_id: '1', id: '2', format: 'json'
    )
  end

  it 'does not expose the retired export and sample data tasks' do
    %w[download_report:agent download_report:inbox download_report:label db:seed:reports_data].each do |task|
      expect(Rake::Task.task_defined?(task)).to be(false)
    end
  end

  it 'retains core seeds and historical report maintenance' do
    %w[db:seed search:setup_test_data reporting_events_rollup:backfill].each do |task|
      expect(Rake::Task.task_defined?(task)).to be(true)
    end
  end
end
