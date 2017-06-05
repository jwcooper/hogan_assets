module HoganAssets
  class Engine < ::Rails::Engine
    initializer "sprockets.hogan", :group => :all do |app|
      HoganAssets::Config.load_yml! if HoganAssets::Config.yml_exists?
      Rails.application.config.assets.configure do |env|
        HoganAssets::Config.template_extensions.each do |ext|
          if env.respond_to?(:register_transformer)
            env.register_mime_type 'text/hogan', extensions: [".#{ext}"], charset: :unicode
            env.register_transformer 'text/hogan', 'application/javascript', Tilt
          end

          if env.respond_to?(:register_engine)
            env.register_engine ".#{ext}", Tilt, silence_deprecation: true
          end
        end
      end
    end
  end
end
