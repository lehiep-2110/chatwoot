class Conversations::AssignmentService
  # Manual API opts into recipient checks; internal Voice callers retain their assignment contract.
  def initialize(conversation:, assignee_id:, assignee_type: nil, validate_assignee_access: false)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
    @validate_assignee_access = validate_assignee_access
  end

  def perform
    agent_bot_assignment? ? assign_agent_bot : assign_agent
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type, :validate_assignee_access

  def assign_agent
    conversation.with_lock do
      # Check the proposed assignment so participating-only custom roles can take ownership.
      conversation.assignee = assignee
      authorize_assignee if validate_assignee_access && assignee

      if open_on_assignment? && conversation.pending?
        conversation.status = :open
        conversation.waiting_since = Time.current if conversation.waiting_since.blank?
      end
      conversation.ai_assignee = nil
      conversation.save!
    end
    assignee
  end

  def authorize_assignee
    assignee_context = {
      user: assignee,
      account: conversation.account,
      account_user: conversation.account.account_users.find_by!(user_id: assignee.id)
    }
    Pundit.authorize(assignee_context, conversation, :show?)
  end

  def assign_agent_bot
    assign_ai_assignee(agent_bot)
  end

  def open_on_assignment?
    assignee.present? && conversation.ai_assignee_type.present?
  end

  def assign_ai_assignee(ai_assignee)
    return unless ai_assignee

    conversation.with_lock do
      conversation.assignee = nil
      conversation.ai_assignee = ai_assignee
      conversation.status = :pending
      conversation.save!
    end
    ai_assignee
  end

  def assignee
    return if assignee_id.blank?

    @assignee ||= if validate_assignee_access
                    conversation.account.users.find(assignee_id)
                  else
                    conversation.account.users.find_by(id: assignee_id)
                  end
  end

  def agent_bot
    @agent_bot ||= AgentBot.accessible_to(conversation.account).find_by(id: assignee_id)
  end

  def agent_bot_assignment?
    assignee_type.to_s == 'AgentBot'
  end
end

Conversations::AssignmentService.prepend_mod_with('Conversations::AssignmentService')
