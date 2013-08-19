module AppBuild
  module Plugin
    class EmberMiddleman < Plugin::Base
      def name; "ember_middleman"; end
      def lifecycle; :before; end
      def path
        "#{base.root}/container/front"
      end
      def run_cmd(cmd,ops={})
        ec "cd #{path} && #{cmd}",ops
      end

      gem "active_model_serializers"
      gem "rack-cors", :require => 'rack/cors'
      
      define_step "create app" do
        ec "cd #{base.root}/container && middleman init front --template=ember"
      end

      define_step "cors initializer" do
        file = "#{base.root}/container/#{base.name}/config/initializers/cors_setup.rb"
        str = <<EOF
#{base.app_name}::Application.config.middleware.use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :options, :put]
  end
end
EOF
        #raise str
        File.create file,str.strip
      end

      def pre!
        super

        AppBuild::Resource.define_step "generate ember app model" do
          ember_type = lambda do |t|
            h = {"integer" => "number", 'references' => 'number'}
            h[t.to_s] || t
          end
           
          col_str = columns.map do |col|
            t = ember_type[col.type]
            "  #{col.name}: DS.attr('#{t}')"
          end.join("\n")
          str = "App.#{class_name} = DS.Model.extend\n#{col_str}\n"
          FileUtils.mkdir_p("#{path}/../front/source/app/models") unless FileTest.exist?("#{path}/../front/source/app/models")
          File.create "#{path}/../front/source/app/models/#{name}.coffee",str
        end

        AppBuild::Resource.define_step "add to ember router" do
          str = "
App.Router.map ->
  @resource '#{name.pluralize}', ->
    @resource '#{name}', {path: '/:#{name}_id'}".strip
          File.append "#{path}/../front/source/app/router.coffee","\n\n#{str}"
        end
      end
    end
  end
end