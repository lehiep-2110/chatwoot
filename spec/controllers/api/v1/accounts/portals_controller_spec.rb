require 'rails_helper'

RSpec.describe 'Retired Help Center routes', type: :routing do
  paths = []
  ['/api/v1/accounts/1/portals', '/api/v1/accounts/1/portals/example/categories', '/api/v1/accounts/1/portals/example/articles'].each do |collection|
    paths += [[:get, collection], [:post, collection], [:get, "#{collection}/1"], [:patch, "#{collection}/1"],
              [:put, "#{collection}/1"], [:delete, "#{collection}/1"], [:get, "#{collection}/new"], [:get, "#{collection}/1/edit"]]
  end
  paths += [[:patch, '/api/v1/accounts/1/portals/example/archive'], [:delete, '/api/v1/accounts/1/portals/example/logo'],
            [:post, '/api/v1/accounts/1/portals/example/send_instructions'], [:get, '/api/v1/accounts/1/portals/example/ssl_status'],
            [:post, '/api/v1/accounts/1/portals/example/articles/reorder'], [:post, '/api/v1/accounts/1/portals/example/categories/reorder'],
            [:post, '/api/v1/accounts/1/portals/example/articles/bulk_actions/translate'],
            [:patch, '/api/v1/accounts/1/portals/example/articles/bulk_actions/update_status'],
            [:patch, '/api/v1/accounts/1/portals/example/articles/bulk_actions/update_category'],
            [:delete, '/api/v1/accounts/1/portals/example/articles/bulk_actions/delete_articles'],
            [:get, '/api/v1/accounts/1/onboarding/help_center_generation'], [:get, '/api/v1/accounts/1/search/articles'],
            [:get, '/.well-known/cf-custom-hostname-challenge/example']]
  %w[/hc/example /hc/example/sitemap.xml /hc/example/en /hc/example/en/search /hc/example/en/articles
     /hc/example/en/categories /hc/example/en/categories/category /hc/example/en/categories/category/articles
     /hc/example/articles/article.png /hc/example/articles/article.md /hc/example/articles/article].each do |path|
    paths << [:get, path]
  end

  paths.each do |method, path|
    it "does not route #{method.upcase} #{path}" do
      expect(method => path).not_to be_routable
    end
  end

  it 'retains core onboarding' do
    expect(patch: '/api/v1/accounts/1/onboarding').to route_to(
      controller: 'api/v1/accounts/onboardings', action: 'update', account_id: '1', format: 'json'
    )
  end

  it 'retains Website messages' do
    expect(get: '/api/v1/widget/messages').to route_to(controller: 'api/v1/widget/messages', action: 'index', format: 'json')
  end
end
