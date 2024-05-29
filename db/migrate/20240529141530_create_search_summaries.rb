class CreateSearchSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :search_summaries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :query
      t.integer :count

      t.timestamps
    end
  end
end
