require 'rails_helper'

RSpec.describe Macro do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  it 'retains macro attachments and existing message history' do
    conversation = create(:conversation, account: account)
    message = create(:message, conversation: conversation, account: account)
    macro = create(:macro, account: account, created_by: user)
    macro.files.attach(io: StringIO.new('historical CV'), filename: 'cv.pdf', content_type: 'application/pdf')
    canned_response = create(:canned_response, account: account)

    account.reset_cache_keys

    expect(account.macros.find(macro.id).files.first.download).to eq('historical CV')
    expect(account.canned_responses.find(canned_response.id).content).to eq(canned_response.content)
    expect(conversation.messages.find(message.id)).to eq(message)
    expect(account.cache_keys.keys).to contain_exactly(:label, :inbox, :team)
  end

  it 'preserves the existing cleanup of personal macro attachments when a user is deleted' do
    macro = create(:macro, account: account, created_by: user)

    expect { user.destroy! }.to change { described_class.exists?(macro.id) }.from(true).to(false)
  end
end
