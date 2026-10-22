require 'rails_helper'

RSpec.describe 'Onboarding without Help Center', type: :request do
  let(:account) { create(:account, domain: 'example.com', custom_attributes: { 'onboarding_step' => 'account_details' }) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  it 'creates the Website inbox without creating portals or enqueueing Help Center generation' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    headers = admin.create_new_auth_token

    expect do
      patch "/api/v1/accounts/#{account.id}/onboarding",
            params: { website: 'acme.com', onboarding_step: 'account_details' }, headers: headers, as: :json
    end.not_to(change { [Portal.count, Article.count, Category.count] })

    expect(response).to have_http_status(:ok)
    expect(account.inboxes.where(channel_type: 'Channel::WebWidget').count).to eq(1)
    expect(enqueued_jobs.map { |job| job[:job] }).not_to include(Onboarding::HelpCenterArticleGenerationJob)
  end

  describe 'jobs queued before Help Center retirement' do
    let!(:portal) { create(:portal, account: account) }
    let!(:article) { create(:article, portal: portal, account: account, author: admin) }
    let(:legacy_arguments) do
      {
        'Portal::ArticleIndexingJob' => [article],
        'Onboarding::HelpCenterArticleGenerationJob' => [account.id, portal.id, admin.id, 'old-generation'],
        'Onboarding::HelpCenterArticleWriterJob' => [account.id, portal.id, admin.id, 'old-generation', { 'url' => 'https://old.example.com' }],
        'Captain::Articles::TranslateJob' => [account, article.id, 'fr', nil, admin],
        'Enterprise::CloudflareVerificationJob' => [portal.id]
      }
    end

    %w[Portal::ArticleIndexingJob Onboarding::HelpCenterArticleGenerationJob Onboarding::HelpCenterArticleWriterJob
       Captain::Articles::TranslateJob Enterprise::CloudflareVerificationJob].each do |name|
      it "consumes a serialized #{name} without HTTP calls or historical changes" do
        serialized = JSON.parse(name.constantize.new(*legacy_arguments.fetch(name)).serialize.to_json)
        attributes = [portal.reload.attributes, article.reload.attributes]
        expect(SafeFetch).not_to receive(:fetch)
        expect(HTTParty).not_to receive(:post)

        expect do
          name.constantize.execute(serialized)
        end.not_to(change { [Portal.count, Article.count, Category.count, ArticleEmbedding.count, enqueued_jobs.size] })

        expect([portal.reload.attributes, article.reload.attributes]).to eq(attributes)
      end
    end

    it 'does not enqueue embeddings when the old account feature is still enabled' do
      account.enable_features!(:help_center_embedding_search)

      expect { article.update!(content: 'Historical content update') }.not_to have_enqueued_job(Portal::ArticleIndexingJob)
    end
  end
end
