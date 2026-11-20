Rails.application.routes.draw do
  root "application#index"
  resources :posts, controller: "application", only: %i[index new create], path: "publicacoes", path_names: { new: "nova" }
  match "tema", to: "application#update_theme", via: [:patch, :put], as: :theme

  # Only reading is public. All uploads pass through the publication form.
  get "anexos/:signed_id/*filename", to: "active_storage/blobs/redirect#show", as: :rails_service_blob
  get "arquivos/:encoded_key/*filename", to: "active_storage/disk#show", as: :rails_disk_service
end
