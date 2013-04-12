module AppBuild
  module Plugin
    class Airbrake < Plugin::Base
      def name; 'airbrake'; end

      gem "airbrake"

      define_step "generate" do
        run_cmd "rails g airbrake --api-key zzz"
        File.gsub "#{path}/config/initializers/airbrake.rb","'zzz'","ENV['AIRBRAKE_API_KEY']"
      end

      define_step "Add js notifier" do
        File.append_after "#{path}/app/views/layouts/application.html.erb","<head>","\n    <%= airbrake_javascript_notifier %>"
      end

      # catch rake
    end
  end
end