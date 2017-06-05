require 'hogan_assets/version'
require 'hogan_assets/config'

module HoganAssets
  extend Config

  autoload :Hogan, 'hogan_assets/hogan'
  autoload :Tilt, 'hogan_assets/tilt'

  if defined? Rails
    require 'hogan_assets/engine'
  else
    require 'sprockets'
    Config.load_yml! if Config.yml_exists?
    Config.template_extensions.each do |ext|
      if Sprockets.respond_to?(:register_transformer)
        Sprockets.register_mime_type 'text/hogan', extensions: [".#{ext}"], charset: :unicode
        Sprockets.register_transformer 'text/hogan', 'application/javascript', Tilt
      end

      if env.respond_to?(:register_engine)
        Sprockets.register_engine ".#{ext}", Tilt, silence_deprecation: true
      end
    end
  end
end
