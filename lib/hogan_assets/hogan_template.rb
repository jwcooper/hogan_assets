require 'tilt'

module HoganAssets
  class HoganTemplate < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def initialize_engine
      HoganRenderer.initialize_engine
    end

    def prepare
      @engine = renderer.choose_engine(data)
    end

    def evaluate(scope, locals, &block)
      source = @engine.render(scope, locals, &block)
      renderer.compile(source)
    end

    private

    def renderer
      @renderer ||= HoganRenderer.new(path: @file)
    end
  end

  # Sprockets 4
  class HoganProcessor

    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    def initialize(options = {})
      @cache_key = [self.class.name, ::HoganAssets::VERSION, options].freeze
    end

    def call(input)
      renderer = HoganRenderer.new(path: input[:filename])
      engine = renderer.choose_engine(input[:data])
      renderer.compile(engine.render)
    end
  end

  class NoOpEngine
    def initialize(data)
      @data = data
    end

    def render(*args)
      @data
    end
  end

  class HoganRenderer
    def self.initialize_engine
      return if @initialized

      begin
        require 'haml'
      rescue LoadError
        # haml not available
      end
      begin
        require 'slim'
      rescue LoadError
        # slim not available
      end

      @initialized = true
    end

    def initialize(options)
      self.class.initialize_engine
      @template_path = TemplatePath.new(options[:path])
    end

    def choose_engine(data)
      if @template_path.is_hamstache?
        Haml::Engine.new(data, HoganAssets::Config.haml_options)
      elsif @template_path.is_slimstache?
        Slim::Template.new(HoganAssets::Config.slim_options) { data }
      else
        NoOpEngine.new(data)
      end
    end

    def compile(source)
      template_path = TemplatePath.new scope
      template_namespace = HoganAssets::Config.template_namespace

      text = if template_path.is_hamstache?
        raise "Unable to compile #{template_path.full_path} because haml is not available. Did you add the haml gem?" unless HoganAssets::Config.haml_available?
        Haml::Engine.new(data, HoganAssets::Config.haml_options.merge(@options)).render(scope, locals)
      elsif template_path.is_slimstache?
        raise "Unable to compile #{template_path.full_path} because slim is not available. Did you add the slim gem?" unless HoganAssets::Config.slim_available?
        Slim::Template.new(HoganAssets::Config.slim_options.merge(@options)) { data }.render(scope, locals)
      else
        data
      end

      compiled_template = Hogan.compile(text)
      template_name = scope.logical_path.inspect

      # Only emit the source template if we are using lambdas
      text = '' unless HoganAssets::Config.lambda_support?
      <<-TEMPLATE
        this.#{template_namespace} || (this.#{template_namespace} = {});
        this.#{template_namespace}[#{template_path.name}] = new Hogan.Template(#{compiled_template}, #{text.inspect}, Hogan, {});
      TEMPLATE
    end

    protected

    class TemplatePath

      def initialize(path)
        @full_path = path
      end

      def check_extension(ext)
        result = false
        if ext.start_with? '.'
          ext = "\\#{ext}"
          result ||= !(@full_path =~ /#{ext}(\..*)*$/).nil?
        else
          result ||= !(@full_path =~ /\.#{ext}(\..*)*$/).nil?
        end
        result
      end

      def is_hamstache?
        result = false
        ::HoganAssets::Config.hamstache_extensions.each do |ext|
          result ||= check_extension(ext)
        end
        result
      end

      def is_slimstache?
        result = false
        ::HoganAssets::Config.slimstache_extensions.each do |ext|
          result ||= check_extension(ext)
        end
        result
      end

      def name
        template_name
      end

      private

      def relative_path
        @relative_path ||= template_path.gsub(/^#{HoganAssets::Config.path_prefix}\/(.*)$/i, "\\1")
      end

      def template_name
        relative_path.dump
      end
    end
  end
end
