class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :author_name, null: false, limit: 100
      t.date :published_on, null: false
      t.text :body, null: false
      t.timestamps
      t.index [:published_on, :created_at, :id]
    end
  end
end
