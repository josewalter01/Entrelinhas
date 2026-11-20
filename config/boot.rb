ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup"

if ENV["COVERAGE"] == "1"
  require "simplecov"
  SimpleCov.start do
    add_filter { |file| !file.filename.start_with?(File.join(root, "app/")) }
    track_files "app/**/*.rb"
    minimum_coverage 90
  end
end
