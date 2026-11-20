Rails.application.routes.draw do
  root "posts#index"
  resources :posts, only: %i[index new create], path: "publicacoes", path_names: { new: "nova" }
  resource :theme, only: :update, path: "tema"

  # Only reading is public. All uploads pass through the publication form.
  get "anexos/:signed_id/*filename", to: "active_storage/blobs/redirect#show", as: :rails_service_blob
  get "arquivos/:encoded_key/*filename", to: "active_storage/disk#show", as: :rails_disk_service
end
