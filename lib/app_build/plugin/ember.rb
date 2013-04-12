module AppBuild
  module Plugin
    class Ember < Plugin::Base
      def name; "ember"; end

      gem "ember-rails"#, :github => "emberjs/ember-rails"

      define_step "add ember config env" do
        File.append_after "#{path}/config/application.rb","config.assets.enabled = true","\n    config.ember.variant = :development"
      end

      define_step "bootstrap" do
        run_cmd "rails g ember:bootstrap"
      end
    end

    class EmberApp < Plugin::Base
      def name; "ember_app"; end
      def lifecycle; :before; end
      def path
        "#{base.root}/container/front"
      end
      def run_cmd(cmd,ops={})
        ec "cd #{path} && #{cmd}",ops
      end

      gem "active_model_serializers"
      
      define_step "create app" do
        ec "mkdir #{path}"
        run_cmd "ember create js"
      end

      define_step "build" do
        run_cmd "ember build"
      end

      define_step "link into rails app" do
        run_cmd "ln -s #{path} #{base.path}/public/front"
      end

      define_step "add guard to Procfile" do
        File.append "#{base.path}/Procfile","front_guard: guard -G public/front/Guardfile -w public/front"
      end

      define_step "guardfile" do
        str = <<EOF
guard 'shell' do
  watch(/.*\.handlebars/) do
    puts `ember build` 
  end
  watch(/.*\.js/) do |m|
    #puts `ember build`
    #puts m.inspect
    skip = %w(js/index.js js/templates.js js/application.js)
    puts `ember build` unless skip.include?(m.first)
  end
end
EOF
        File.create "#{path}/Guardfile",str
      end

      def pre!
        super
        AppBuild::Resource.define_step "generate ember app model" do
          ember_type = lambda do |t|
            h = {"integer" => "number", 'references' => 'number'}
            h[t] || t
          end
          col_str = columns.map { |c| "#{c.name}:#{ember_type[c.type]}" }.join(" ")
          run_cmd "cd ../front && ember generate --scaffold #{name} #{col_str}"
        end
      end
    end
  end
end