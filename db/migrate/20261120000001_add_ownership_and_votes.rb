class AddOwnershipAndVotes < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :author_key, :string
    create_table :votes do |t|
      t.references :post, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :voter_key, null: false
      t.integer :value, null: false
      t.index [:post_id, :voter_key], unique: true
      t.check_constraint "value IN (-1, 1)", name: "votes_valid_value"
    end
  end
end
