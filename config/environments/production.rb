Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = :info
  config.hosts << "entrelinhas-production-490f5296.up.railway.app"
end
