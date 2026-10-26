# == Schema Information
#
# Table name: applied_slas
#
#  id              :bigint           not null, primary key
#  sla_status      :integer          default("active")
#  completed_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  sla_policy_id   :bigint           not null
#
# Indexes
#
#  index_applied_slas_on_account_id                       (account_id)
#  index_applied_slas_on_account_sla_policy_conversation  (account_id,sla_policy_id,conversation_id) UNIQUE
#  index_applied_slas_on_conversation_id                  (conversation_id)
#  index_applied_slas_on_sla_policy_id                    (sla_policy_id)
#
# Historical records only; no SLA evaluation, deadlines or realtime callbacks.
class AppliedSla < ApplicationRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :conversation

  has_many :sla_events, dependent: :destroy_async

  enum sla_status: { active: 0, hit: 1, missed: 2, active_with_misses: 3 }
end
