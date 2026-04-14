require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nomina
  class Application < Rails::Application
    config.load_defaults 8.1
    config.i18n.default_locale = :es

    config.autoload_lib(ignore: %w[assets tasks])

    config.beginning_of_week = :monday
  end
end
