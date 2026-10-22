require 'rails_helper'

RSpec.describe Portal do
  it 'does not schedule SSL verification for historical portal changes' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    portal = create(:portal)

    expect { portal.update!(custom_domain: 'retired.example.com') }.not_to have_enqueued_job(Enterprise::CloudflareVerificationJob)
  end
end
