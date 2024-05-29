class User < ApplicationRecord
  has_many :search_queries, dependent: :destroy
  has_many :search_summaries, dependent: :destroy
end
