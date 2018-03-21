require 'hogan_assets/version'
require 'hogan_assets/config'

module HoganAssets
  autoload :Config, 'hogan_assets/config'
  autoload :Hogan, 'hogan_assets/hogan'
  autoload :HoganTemplate, 'hogan_assets/hogan_template'
  autoload :HoganProcessor, 'hogan_assets/hogan_template'

  PATH = File.expand_path('../../vendor/assets/javascripts', __FILE__)

  def self.path
    PATH
  end

  def self.configure
    yield Config
  end

  def self.register_extensions(sprockets_environment)
    if Gem::Version.new(Sprockets::VERSION) < Gem::Version.new('3')
      Config.template_extensions.each do |ext|
        sprockets_environment.register_engine(ext, HoganTemplate)
      end
    else
      sprockets_environment.register_mime_type 'text/x-hogan-template', extensions: Config.handlebars_extensions
      if Config.slim_enabled? && Config.slim_available?
        sprockets_environment.register_mime_type 'text/x-hogan-template', extensions: Config.slimstache_extensions
      end
      if Config.haml_enabled? && Config.haml_available?
        sprockets_environment.register_mime_type 'text/x-hogan-template', extensions: Config.hamstache_extensions
      end
      sprockets_environment.register_transformer 'text/x-hogan-template', 'application/javascript', HoganProcessor
    end
  end

  def self.register_transformers(config)
    config.assets.configure do |env|
      env.register_mime_type 'text/x-hogan-template', extensions: Config.hogan_extensions
      env.register_transformer 'text/x-hogan-template', 'application/javascript', HoganProcessor
    end
  end

  def self.add_to_asset_versioning(sprockets_environment)
    sprockets_environment.version += "-#{HoganAssets::VERSION}"
  end
end

if defined?(Rails)
  require 'hogan_assets/engine'
else
  require 'sprockets'
  ::HoganAssets.register_extensions(Sprockets)
end
