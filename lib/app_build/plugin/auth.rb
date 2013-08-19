module AppBuild
  module Plugin
    class Auth < Plugin::Base
      def name; "auth"; end

      gem 'ember_auth_rails', :github => "mharris717/ember_auth_rails", :branch => :master
      gem "multiauth", :github => "mharris717/multiauth", :branch => :master

      define_step "migrations" do
        run_cmd "rake multiauth_engine:install:migrations"
        run_cmd "rake ember_auth_rails_engine:install:migrations"
      end

      define_step "add login partial to layout" do
        File.append_after "#{path}/app/views/layouts/application.html.erb","<body>","\n  <%= render :partial => 'layouts/user' %>"
      end
    end
  end
end