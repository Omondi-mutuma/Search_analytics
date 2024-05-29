class SearchSummary < ApplicationRecord
  belongs_to :user
  validates :query, presence: true, uniqueness: { scope: :user_id }
  validates :count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
