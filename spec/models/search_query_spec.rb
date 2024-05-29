require 'rails_helper'

RSpec.describe SearchQuery, type: :model do
  let(:user) { User.create(email: "test@example.com") }
  let!(:query1) { SearchQuery.create(user: user, query: "What is") }
  let!(:query2) { SearchQuery.create(user: user, query: "What is a") }
  let!(:query3) { SearchQuery.create(user: user, query: "What is a good car") }

  it 'removes incomplete queries and keeps the final meaningful query' do
    Rails.logger.info "Starting test for removing incomplete queries"

    ProcessSearchQueriesJob.perform_now

    Rails.logger.info "Completed job processing"
    expect(user.search_summaries.count).to eq(1)
    expect(user.search_summaries.first.query).to eq("What is a good car")

    Rails.logger.info "Final search summaries: #{user.search_summaries.pluck(:query, :count).inspect}"
  end
end
