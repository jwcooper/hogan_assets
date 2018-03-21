module HoganAssets
  class Engine < ::Rails::Engine
    initializer "hogan_assets.assets.register", :group => :all do |app|
      app.config.assets.configure do |sprockets_env|
        ::HoganAssets::register_extensions(sprockets_env)
        if Gem::Version.new(Sprockets::VERSION) < Gem::Version.new('3')
          ::HoganAssets::add_to_asset_versioning(sprockets_env)
        end
      end
    end
  end
end
