# Real-time Search Analytics Project Documentation
- # Overview

This project is designed to create a real-time search box that records user search queries for articles and provides analytics on what users are searching for. The goal is to capture complete search queries, filter out incomplete queries, and summarize the searches to avoid the pyramid problem.

This project is designed to run using a predetermined search query 'What is a good car' and logs all processes in the /log directory.

# How to run the test suite
    > bundle exec rspec


# Ruby version: 
    ruby 3.2.4 (2024-04-23 revision af471c0e01) [x64-mingw-ucrt]

# System dependencies : 
    rspec

# How to run the test suite
    >bundle exec rspec

# Services (job queues, cache servers, search engines, etc.)
    1 background job/process

# Deployment instructions

# ...............................................................................................

# Overview

This project is designed to create a real-time search box that records user search queries for articles and provides analytics on what users are searching for. The goal is to capture complete search queries, filter out incomplete queries, and summarize the searches to avoid the pyramid problem.

 Key Features

- **Real-time Search Logging**: Capture user search inputs as they type.
- **Filtering**: Only retain complete and meaningful search queries.
- **Analytics**: Summarize search queries to show what users are searching for.
- **Scalability**: Designed to handle thousands of requests per hour.
- **Testing**: Implemented RSpec tests for validation.
# ....................................................................................................
# Project Setup

 Step 1: Creating a New Rails Project

```sh
rails new search_analytics
cd search_analytics
```
# ...........................................................................................
 Step 2: Generating Models

```sh
rails generate model User email:string
rails generate model SearchQuery user:references query:string
rails generate model SearchSummary user:references query:string count:integer, default: 0
rails db:migrate
```
# ...........................................................................................
 Step 3: Creating the Controller

**app/controllers/searches_controller.rb**

```ruby
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
```
# ...........................................................................................
 Step 4: Implementing the Job

**app/jobs/process_search_queries_job.rb**

```ruby
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
```
# ...........................................................................................
 Step 5: Configure Routes

**config/routes.rb**

```ruby
Rails.application.routes.draw do
  resources :searches, only: [:create]
end
```
# ...........................................................................................
 Step 6: Log Configuration

Ensure that your logging level is set appropriately to see the info logs.

**config/environments/development.rb**

```ruby
Rails.application.configure do
  # Other configurations...
  
  config.log_level = :debug
end
```
# ...........................................................................................


# Improvements and Fixes

 Problem 1: Undefined Method Error
- **Issue**: `NoMethodError: undefined method '+' for nil:NilClass`
- **Solution**: Ensure `summary.count` is initialized properly.

**app/jobs/process_search_queries_job.rb**
```ruby
summary.count ||= 0
summary.count += 1
```

 Problem 2: Missing Attribute in User Model
- **Issue**: `ActiveModel::UnknownAttributeError: unknown attribute 'name' for User.`
- **Solution**: Updated User model and tests to reflect correct attributes.

**db/migrate/xxxxx_create_users.rb**
```ruby
class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email

      t.timestamps
    end
  end
end
```

**spec/models/search_query_spec.rb**
```ruby
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
```

# Log Statements Added

- **Controller (SearchesController)**: Logs the received search query.
- **Job (ProcessSearchQueriesJob)**: Logs the following:
  - When the job starts and finishes.
  - The user being processed.
  - Initial queries.
  - Final queries to keep.
  - Updates to `SearchSummary`.
  - Deleted queries.
- **Tests**: Logs the start and completion of tests and final search summaries.

# Running Tests

To run the tests and view the log outputs, execute:

```sh
bundle exec rspec
```

# Conclusion

This project captures and processes real-time search queries, filters out incomplete queries, and logs meaningful search queries for analytics. With the improvements and fixes applied, the application ensures complete and accurate logging of user search behavior, providing valuable insights for analytics.