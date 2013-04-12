module AppBuild
  module Plugin
    class ActiveAdmin < Plugin::Base
      def name; "heroku"; end

      gem :activeadmin
      gem :meta_search

      def pre!
        super
        AppBuild::Resource.define_step "create resource admin" do
          run_cmd "rails g active_admin:resource #{class_name}"
        end
      end

      define_step "install" do
        run_cmd "rails generate active_admin:install"
      end

      #define_step "fix admin_user file" do
      #  FileUtils.mv "#{path}/app/admin/admin_user.rb","#{path}/app/admin/user.rb"
      #  File.gsub "#{path}/app/admin/user.rb","AdminUser","User"
      #end

    end
  end
end