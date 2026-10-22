module Enterprise::Concerns::Article
  extend ActiveSupport::Concern

  included do
    has_many :article_embeddings, dependent: :destroy_async
  end
end
