module AppBuild
  module Plugin
    class ErrorReporting < Plugin::Base
      def name; "error_reporting"; end

      gem 'better_errors'
      gem 'binding_of_caller'
      #gem 'quiet_assets'
      #gem 'pry-rails'

      define_step "Set trusted ip" do
        File.create "#{path}/config/initializers/error_ip.rb","if ENV['TRUSTED_IP']
        BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] 
        puts 'setting trusted ip'
        puts ENV['TRUSTED_IP']
      end"
      end

      define_step "ip task" do
        str = <<EOF
        task :set_trusted_ip do
          require 'json'
          require 'open-uri'
          require 'mharris_ext'

          str = open("http://ifconfig.me/all.json").read
          ip = JSON.parse(str)['ip_addr']
          ec "heroku config:set TRUSTED_IP="+ip.to_s
          ec "heroku restart"
        end
EOF
        File.create "#{path}/lib/tasks/error_ip.rake",str
      end

      define_step "make always" do
        str = <<EOF
        module BetterErrors
          class Railtie
            def use_better_errors?
              Rails.env.production? and app.config.consider_all_requests_local
            end
          end
        end
EOF
        File.append "#{path}/config/application.rb","\n\n#{str}"
      end
    end
  end
end