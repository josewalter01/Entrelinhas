class AddAuthorPhotoUrlToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :author_photo_url, :string, limit: 1024
  end
end
