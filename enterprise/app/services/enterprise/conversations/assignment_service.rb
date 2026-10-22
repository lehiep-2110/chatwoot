module Enterprise::Conversations::AssignmentService
  def perform
    # A retired Captain id must never fall through and select an HR user with the same numeric id.
    return if assignee_type.to_s == 'Captain::Assistant'

    super
  end

  private

  def open_on_assignment?
    super || conversation.ai_assignee_type == 'Captain::Assistant'
  end
end
