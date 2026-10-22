require 'rails_helper'

RSpec.describe 'Retired Captain jobs and legacy records', type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:document) { create(:captain_document, account: account, assistant: assistant, status: :available) }
  let(:response_record) { create(:captain_assistant_response, account: account, assistant: assistant) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
  let(:portal) { create(:portal, account: account) }
  let(:article) { create(:article, account: account, portal: portal, author: user) }
  let(:arguments) do
    {
      'Captain::Articles::TranslateJob' => [account, article.id, 'fr', nil, user],
      'Captain::Conversation::ResponseBuilderJob' => [conversation, assistant, nil],
      'Captain::Documents::CrawlJob' => [document],
      'Captain::Documents::PerformSyncJob' => [document],
      'Captain::Documents::ResponseBuilderJob' => [document, {}],
      'Captain::Documents::ScheduleSyncsJob' => ['enterprise'],
      'Captain::InboxPendingConversationsResolutionJob' => [inbox],
      'Captain::Llm::ConversationFaqJob' => [conversation, assistant],
      'Captain::Llm::UpdateEmbeddingJob' => [response_record, 'Historical content'],
      'Portal::ArticleIndexingJob' => [article],
      'Onboarding::HelpCenterArticleGenerationJob' => [account.id, portal.id, user.id, 'legacy'],
      'Onboarding::HelpCenterArticleWriterJob' => [account.id, portal.id, user.id, 'legacy', { 'url' => 'https://retired.example.com' }]
    }
  end
  let(:keywords) do
    ids = { assistant: assistant, conversation_id: conversation.id, user_id: user.id, copilot_thread_id: copilot_thread.id }
    {
      'Captain::Copilot::ReplySuggestionJob' => ids,
      'Captain::Copilot::ResponseJob' => ids.merge(message: 'Legacy message'),
      'Captain::Tools::FirecrawlParserJob' => { assistant_id: assistant.id, payload: {} },
      'Captain::Tools::SimplePageCrawlParserJob' => { assistant_id: assistant.id, page_link: 'https://retired.example.com' }
    }
  end

  [
    'Captain::Articles::TranslateJob',
    'Captain::Conversation::ResponseBuilderJob',
    'Captain::Copilot::ReplySuggestionJob',
    'Captain::Copilot::ResponseJob',
    'Captain::Documents::CrawlJob',
    'Captain::Documents::PerformSyncJob',
    'Captain::Documents::ResponseBuilderJob',
    'Captain::Documents::ScheduleSyncsJob',
    'Captain::InboxPendingConversationsResolutionJob',
    'Captain::Llm::ConversationFaqJob',
    'Captain::Llm::UpdateEmbeddingJob',
    'Captain::Tools::FirecrawlParserJob',
    'Captain::Tools::SimplePageCrawlParserJob',
    'Portal::ArticleIndexingJob',
    'Onboarding::HelpCenterArticleGenerationJob',
    'Onboarding::HelpCenterArticleWriterJob'
  ].each do |name|
    it "consumes serialized #{name} without AI/network calls or changing historical data" do
      serialized = JSON.parse(name.constantize.new(*arguments.fetch(name, []), **keywords.fetch(name, {})).serialize.to_json)
      attributes = [conversation.reload.attributes, document.reload.attributes, response_record.reload.attributes]
      expect(HTTParty).not_to receive(:post)
      expect(HTTParty).not_to receive(:get)
      expect(SafeFetch).not_to receive(:fetch)

      expect do
        name.constantize.execute(serialized)
      end.not_to(change do
        [Message.count, Conversation.count, Captain::Document.count, ArticleEmbedding.count, CopilotMessage.count, enqueued_jobs.size]
      end)

      expect([conversation.reload.attributes, document.reload.attributes, response_record.reload.attributes]).to eq(attributes)
    end
  end

  it 'does not register Captain listeners with either dispatcher' do
    async_listeners = Rails.configuration.dispatcher.async_dispatcher.listeners
    expect(async_listeners.map { |listener| listener.class.name }).not_to include('CaptainListener', 'Captain::ReportingEventListener')
    sync_names = Rails.configuration.dispatcher.sync_dispatcher.listeners.map { |listener| listener.class.name }
    expect(sync_names).not_to include('Captain::ConversationOutcomeEventListener')
    expect(async_listeners).to include(AutomationRuleListener.instance, WebhookListener.instance)
  end

  it 'does not schedule document sync or Captain auto-resolution from shared schedulers' do
    Internal::TriggerDailyScheduledItemsJob.perform_now
    Account::ConversationsResolutionSchedulerJob.perform_now

    expect(enqueued_jobs.map { |job| job[:job] }).not_to include(
      Captain::Documents::ScheduleSyncsJob, Captain::InboxPendingConversationsResolutionJob
    )
  end

  it 'does not activate a historical Captain connection or assign it to new conversations' do
    account.enable_features!('captain_integration', 'captain_integration_v2')
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)

    expect(inbox.reload.captain_active?).to be false
    expect(inbox.active_bot?).to be false
    expect(conversation).to have_attributes(status: 'open', ai_assignee: nil)
  end
end
