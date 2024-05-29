class SearchesController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    query = params[:query]
    Rails.logger.info "Received search query: #{query}"
    @search_query = User.first.search_queries.create(query: query) # Assuming single user for simplicity
    ProcessSearchQueriesJob.perform_later
    head :ok
  end
end
