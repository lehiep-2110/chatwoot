require 'rails_helper'

RSpec.describe '/api/v1/widget/events', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  describe 'POST /api/v1/widget/events' do
    let(:params) { { website_token: web_widget.website_token, name: 'webwidget.triggered', event_info: { test_id: 'test' } } }

    context 'with invalid website token' do
      it 'returns unauthorized' do
        post '/api/v1/widget/events', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with correct website token' do
      before do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
      end

      it 'dispatches the webwidget event' do
        post '/api/v1/widget/events',
             params: params,
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:no_content)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(params[:name], anything, contact_inbox: contact_inbox,
                                         event_info: { test_id: 'test', browser_language: nil, widget_language: nil, browser: anything })
      end

      it 'continues delivering webwidget events to external bots and webhooks' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
        headers = { 'X-Auth-Token' => token }
        expect(AgentBotListener.instance).to receive(:webwidget_triggered).with(an_instance_of(Events::Base)).once
        expect(WebhookListener.instance).to receive(:webwidget_triggered).with(an_instance_of(Events::Base)).once

        perform_enqueued_jobs(only: EventDispatcherJob) do
          post '/api/v1/widget/events', params: params, headers: headers, as: :json
        end

        expect(response).to have_http_status(:no_content)
      end

      context 'with a retired campaign event' do
        let!(:campaign) { create(:campaign, account: account, inbox: web_widget.inbox) }

        before do
          allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
        end

        %w[campaign.triggered campaign_triggered].each do |event_name|
          it "rejects #{event_name} without creating conversations, messages or jobs" do
            headers = { 'X-Auth-Token' => token }
            campaign_params = params.merge(name: event_name, event_info: { campaign_id: campaign.reload.display_id })
            expect(Rails.configuration.dispatcher).not_to receive(:dispatch)

            expect do
              post '/api/v1/widget/events', params: campaign_params, headers: headers, as: :json
            end.not_to(change { [Conversation.count, Message.count, enqueued_jobs.size] })

            expect(response).to have_http_status(:gone)
          end
        end
      end
    end
  end
end
