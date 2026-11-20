require_relative "boot"
require "rails"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_storage/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Caderno
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "America/Fortaleza"
    config.i18n.default_locale = :"pt-BR"
    config.active_storage.service = :local
    config.active_storage.draw_routes = false
    config.active_storage.variant_processor = :disabled
    config.active_storage.track_variants = false
    config.active_storage.analyzers = []
    config.active_storage.previewers = []
    config.active_storage.content_types_allowed_inline = %w[image/jpeg image/png image/webp]
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.script_src :none
      policy.object_src :none
      policy.base_uri :none
      policy.form_action :self
      policy.frame_ancestors :none
    end
  end
end
