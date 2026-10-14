require 'rails_helper'

RSpec.describe Conversations::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved).reload }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:custom_role) { create(:custom_role, account: account, permissions: permissions) }
  let(:service) { described_class.new(conversation: conversation, assignee_id: agent.id, validate_assignee_access: true) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    agent.account_users.find_by!(account: account).update!(custom_role: custom_role)
  end

  context 'when the assignee can manage only participating conversations' do
    let(:permissions) { ['conversation_participating_manage'] }

    it 'allows assignment because the agent will be the assignee' do
      expect(service.perform).to eq(agent)
      expect(conversation.reload).to have_attributes(assignee: agent, status: 'resolved')
    end
  end

  context 'when the assignee can manage unassigned conversations' do
    let(:permissions) { ['conversation_unassigned_manage'] }

    it 'allows assignment because the agent will be the assignee' do
      expect(service.perform).to eq(agent)
      expect(conversation.reload.assignee).to eq(agent)
    end
  end

  context 'when the assignee has no conversation management permission' do
    let(:permissions) { ['contact_manage'] }

    it 'rejects assignment even when the agent is an inbox member' do
      original_assignee = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: original_assignee)
      conversation.update!(assignee: original_assignee)

      expect { service.perform }.to(raise_error { |error| expect(error.class.name).to eq('Pundit::NotAuthorizedError') })
      expect(conversation.reload).to have_attributes(assignee: original_assignee, status: 'resolved')
    end
  end
end
