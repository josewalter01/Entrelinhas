Rails.application.routes.draw do
  get "auth/suap", to: "suap_sessions#start", as: :suap_login
  get "auth/suap/callback", to: "suap_sessions#callback"
  delete "auth/sair", to: "suap_sessions#destroy", as: :logout

  root "application#index"
  resources :posts, controller: "application", only: %i[index new create destroy], path: "publicacoes", path_names: { new: "nova" }
  get "publicacoes/:id/voto", to: "application#ballot"
  put "publicacoes/:id/voto", to: "application#vote", as: :vote_post
  match "tema", to: "application#update_theme", via: [:patch, :put], as: :theme

  # Only reading is public. All uploads pass through the publication form.
  get "anexos/:signed_id/*filename", to: "active_storage/blobs/redirect#show", as: :rails_service_blob
  get "arquivos/:encoded_key/*filename", to: "active_storage/disk#show", as: :rails_disk_service
end
