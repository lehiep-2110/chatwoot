require 'rails_helper'

RSpec.describe PortalInstructionsMailer do
  it 'consumes a queued legacy delivery without sending email or changing its portal' do
    portal = create(:portal, custom_domain: 'retired.example.com')
    attributes = portal.reload.attributes

    expect do
      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        described_class.send_cname_instructions(portal: portal, recipient_email: 'admin@example.com').deliver_later
      end
    end.not_to(change { ActionMailer::Base.deliveries.size })

    expect(portal.reload.attributes).to eq(attributes)
  end
end
