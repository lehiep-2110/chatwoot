# == Schema Information
#
# Table name: macros
#
#  id            :bigint           not null, primary key
#  actions       :jsonb            not null
#  name          :string           not null
#  visibility    :integer          default("personal")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint
#  updated_by_id :bigint
#
# Indexes
#
#  index_macros_on_account_id  (account_id)
#
# Retained for historical attachments and account/user cleanup, without macro execution.
class Macro < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: :User, optional: true, inverse_of: :macros
  belongs_to :updated_by, class_name: :User, optional: true
  has_many_attached :files

  enum visibility: { personal: 0, global: 1 }
end
