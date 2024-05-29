class ProcessSearchQueriesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting ProcessSearchQueriesJob"
    User.find_each do |user|
      Rails.logger.info "Processing user: #{user.id}"

      queries = user.search_queries.order(:created_at)
      Rails.logger.info "Initial queries: #{queries.pluck(:query).inspect}"

      final_queries = []

      queries.each_with_index do |query, index|
        next_query = queries[index + 1]
        if next_query.nil? || !next_query.query.start_with?(query.query)
          final_queries << query
        end
      end

      Rails.logger.info "Final queries to keep: #{final_queries.map(&:query).inspect}"

      final_queries.each do |query|
        summary = SearchSummary.find_or_initialize_by(user: query.user, query: query.query)
        summary.count ||= 0
        summary.count += 1
        summary.save!
        Rails.logger.info "Updated SearchSummary for query '#{query.query}' to count #{summary.count}"
      end

      deleted_queries = user.search_queries.where.not(id: final_queries.map(&:id)).destroy_all
      Rails.logger.info "Deleted queries: #{deleted_queries.map(&:query).inspect}"
    end
    Rails.logger.info "Finished ProcessSearchQueriesJob"
  end
end
