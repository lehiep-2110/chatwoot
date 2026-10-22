# == Schema Information
#
# Table name: article_embeddings
#
#  id         :bigint           not null, primary key
#  embedding  :vector(1536)
#  term       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#
# Indexes
#
#  index_article_embeddings_on_embedding  (embedding) USING ivfflat
#
class ArticleEmbedding < ApplicationRecord
  belongs_to :article
  has_neighbors :embedding, normalize: true

  delegate :account_id, to: :article
end
