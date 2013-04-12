module AppBuild
  module Plugin
    class Heroku < Plugin::Base
      def name; "heroku"; end
      def lifecycle; :after; end

      fattr(:addons) { [] }
      def addon(name)
        self.addons << name
      end

      define_step "create app" do
        eat_exceptions do
          run_cmd "heroku apps:destroy --app #{base.name} --confirm #{base.name}"
        end
        run_cmd "heroku create #{base.name}"
      end

      define_step "push app" do
        run_cmd "git push heroku master"
      end

      define_step "db migrate" do
        run_cmd "heroku run rake db:migrate"
      end

      define_step "seed data" do
        run_cmd "heroku run rake db:seed"
      end

      define_step "add addons" do
        addons.each do |addon|
          run_cmd "heroku addons:add #{addon}"
        end
      end

      define_step "restart" do
        run_cmd "heroku restart"
      end

      define_step "dump env vars" do
        File.append "#{path}/.gitignore","\n.env"
        run_cmd "heroku config -s > .env"
      end

      define_step "Set ip" do
        run_cmd "rake set_trusted_ip"
      end
    end
  end
end