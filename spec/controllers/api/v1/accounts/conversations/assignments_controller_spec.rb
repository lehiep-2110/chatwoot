require 'rails_helper'

RSpec.describe 'Conversation Assignment API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/assignments' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated bot with out access to the inbox' do
      let(:agent_bot) { create(:agent_bot) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             headers: { api_access_token: agent_bot.access_token.token },
             params: {
               assignee_id: agent.id
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to the inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:team) { create(:team, account: account) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'assigns a user to the conversation' do
        params = { assignee_id: agent.id }

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'assigns an agent bot to the conversation' do
        params = { assignee_id: agent_bot.id, assignee_type: 'AgentBot' }

        expect(Conversations::AssignmentService).to receive(:new)
          .with(hash_including(conversation: conversation, assignee_id: agent_bot.id, assignee_type: 'AgentBot'))
          .and_call_original

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq(agent_bot.name)
        conversation.reload
        expect(conversation.ai_assignee).to eq(agent_bot)
        expect(conversation.assignee).to be_nil
      end

      it 'assigns a team to the conversation' do
        team_member = create(:user, account: account, role: :agent, auto_offline: false)
        create(:inbox_member, inbox: conversation.inbox, user: team_member)
        create(:team_member, team: team, user: team_member)
        params = { team_id: team.id }

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to eq(team)
        # assignee will be from team
        expect(conversation.reload.assignee).to eq(team_member)
      end
    end

    context 'when it is an authenticated bot with access to the inbox' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }

      before do
        create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot)
      end

      it 'assignment of an agent in the conversation by bot agent' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)

        conversation.update!(assignee_id: nil)
        expect(conversation.reload.assignee).to be_nil

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             headers: { api_access_token: agent_bot.access_token.token },
             params: {
               assignee_id: agent.id
             },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'assignment of an team in the conversation by bot agent' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)

        conversation.update!(team_id: nil)
        expect(conversation.reload.team).to be_nil

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments",
             headers: { api_access_token: agent_bot.access_token.token },
             params: {
               team_id: team.id
             },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to eq(team)
      end
    end

    context 'when conversation already has an assignee' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        conversation.update!(assignee: agent)
      end

      it 'unassigns the assignee from the conversation' do
        params = { assignee_id: nil }
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to be_nil
        expect(Conversations::ActivityMessageJob)
          .to(have_been_enqueued.at_least(:once)
        .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                              content: "Conversation unassigned by #{agent.name}" }))
      end
    end

    context 'when conversation already has a team' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }

      before do
        conversation.update!(team: team)
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'unassigns the team from the conversation' do
        params = { team_id: 0 }
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to be_nil
      end
    end

    context 'when checking the human assignee access' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:original_assignee) { create(:user, account: account, role: :agent) }
      let(:recipient) { create(:user, account: account, role: :agent) }
      let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        create(:inbox_member, inbox: inbox, user: original_assignee)
        conversation.update!(assignee: original_assignee, status: :resolved)
      end

      it 'rejects an assignee from another account without clearing the current assignment' do
        foreign_agent = create(:user, account: create(:account), role: :agent)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: foreign_agent.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(conversation.reload).to have_attributes(assignee: original_assignee, status: 'resolved')
      end

      it 'rejects a team from another account without changing the conversation' do
        foreign_team = create(:team, account: create(:account))

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { team_id: foreign_team.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(conversation.reload).to have_attributes(assignee: original_assignee, team: nil, status: 'resolved')
      end

      it 'rejects an agent without inbox or conversation team access' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload).to have_attributes(assignee: original_assignee, status: 'resolved')
      end

      it 'rejects an agent whose only team does not own the conversation' do
        other_team = create(:team, account: account)
        create(:team_member, team: other_team, user: recipient)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload.assignee).to eq(original_assignee)
      end

      it 'does not inherit administrator privileges from another account' do
        create(:account_user, account: create(:account), user: recipient, role: :administrator)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload.assignee).to eq(original_assignee)
      end

      it 'accepts a member of the inbox' do
        create(:inbox_member, inbox: inbox, user: recipient)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(recipient.id)
        expect(conversation.reload).to have_attributes(assignee: recipient, status: 'resolved')
      end

      it 'rejects a member of the conversation team without inbox membership' do
        team = create(:team, account: account, allow_auto_assign: false)
        create(:team_member, team: team, user: recipient)
        create(:team_member, team: team, user: original_assignee)
        conversation.update!(team: team)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload).to have_attributes(assignee: original_assignee, team: team, status: 'resolved')
      end

      it 'accepts an administrator of this account without inbox membership' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: administrator.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(administrator)
      end

      it 'preserves bot ownership and pending status when the recipient has no access' do
        agent_bot = create(:agent_bot, account: account)
        conversation.update!(assignee: nil, ai_assignee: agent_bot, status: :pending)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload).to have_attributes(assignee: nil, ai_assignee: agent_bot, status: 'pending')
      end

      it 'does not let a request disable assignee access validation' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: recipient.id, validate_assignee_access: false },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(conversation.reload).to have_attributes(assignee: original_assignee, status: 'resolved')
      end
    end
  end
end
