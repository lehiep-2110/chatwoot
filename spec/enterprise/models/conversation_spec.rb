require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policy).optional }
  end

  describe 'assignment capacity limits' do
    describe 'team assignment with inbox auto-assignment disabled' do
      let(:account) { create(:account) }
      let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false, auto_assignment_config: { max_assignment_limit: 1 }) }
      let(:team) { create(:team, account: account, allow_auto_assign: true) }
      let!(:agent1) { create(:user, account: account, role: :agent, auto_offline: false) }
      let!(:agent2) { create(:user, account: account, role: :agent, auto_offline: false) }

      before do
        create(:inbox_member, inbox: inbox, user: agent1)
        create(:inbox_member, inbox: inbox, user: agent2)
        create(:team_member, team: team, user: agent1)
        create(:team_member, team: team, user: agent2)
        # Both agents are over the limit (simulate by assigning open conversations)
        create_list(:conversation, 2, inbox: inbox, assignee: agent1, status: :open)
        create_list(:conversation, 2, inbox: inbox, assignee: agent2, status: :open)
      end

      it 'does not enforce max_assignment_limit for team assignment when inbox auto-assignment is disabled' do
        conversation = create(:conversation, inbox: inbox, account: account, assignee: nil, status: :open)

        # Assign to team to trigger the assignment logic
        conversation.update!(team: team)

        # Should assign to a team member even if they are over the limit
        expect(conversation.reload.assignee).to be_present
        expect([agent1, agent2]).to include(conversation.reload.assignee)
      end
    end
  end
end
