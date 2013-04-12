module AppBuild
  module BaseRef
    def run_cmd(*args)
      base.run_cmd(*args)
    end
    def path
      base.path
    end
  end

  class Base
    include FromHash
    include DefineStep
    attr_accessor :root, :name, :root_resource
    def path
      "#{root}/container/#{name}"
    end
    fattr(:gems) { [] }
    fattr(:resources) { [] }
    fattr(:plugins) { [] }

    def main_plugins
      plugins.select { |x| x.lifecycle == :main }
    end
    def after_plugins
      plugins.select { |x| x.lifecycle == :after }
    end
    def before_plugins
      plugins.select { |x| x.lifecycle == :before }
    end

    def run_cmd(cmd,ops={})
      if ops[:path] == :container
        ops.delete(:path)
        ec "cd #{root}/container && #{cmd}", ops
      else
        ec "cd #{path} && #{cmd}", ops
      end
    end


    define_step "setup root" do
      #FileUtils.mkdir_p(root) unless FileTest.exist?(root)
      ec "cd #{root} && rm -rf *"
      FileUtils.mkdir "#{root}/container"
      ec "cd #{root}/container && git init"
    end


    define_step "create app" do
      #FileUtils.rm_r "#{path}" if FileTest.exist?(path)
      ec "cd #{root}/container && rails new #{name}"
      #FileUtils.cp_r "#{path}_fresh",path
    end

   

    define_step "run plugins pre", :skip => false do
      plugins.each { |x| x.pre! }
    end

    define_step "remove sqlite" do
      File.gsub "#{path}/Gemfile","gem 'sqlite3'",""
    end

    define_step "add gems" do
      gem_str = gems.join("\n")
      File.append "#{path}/Gemfile","\n\n#{gem_str}"
    end

    define_step "set ruby version" do
      File.prepend "#{path}/Gemfile","ruby '1.9.3'\n"
    end



    define_step "bundle install after gems" do
      run_cmd "bundle install"
    end

    define_step "Database yml" do
      ops = {}
      ops['development'] = {'adapter' => "postgresql", 'database' => "#{name}_dev", "host" => "localhost", "prepared_statements" => false}
      ops['production'] = {'adapter' => "postgresql", 'database' => "#{name}_prod", "host" => "localhost", "prepared_statements" => false}
      str = YAML::dump(ops)[4..-1]
      File.create "#{path}/config/database.yml",str
    end

    define_step "create database" do
      eat_exceptions do
        run_cmd "echo \"drop database #{name}_dev;\" | psql -h localhost"
      end
      eat_exceptions do
        run_cmd "echo \"drop database #{name}_prod;\" | psql -h localhost"
      end
      run_cmd "rake db:create"
    end

    define_step "fix whitelist setting" do
      File.gsub("#{path}/config/application.rb","config.active_record.whitelist_attributes = true","config.active_record.whitelist_attributes = false")
    end

    define_child_step "run plugins before", :before_plugins
    define_child_step "create resources", :resources
    define_child_step "run plugins main", :main_plugins

    define_step "build db" do
      run_cmd "rake db:migrate db:seed"
    end

    define_step "setup root route" do
      FileUtils.rm "#{path}/public/index.html"
      run_cmd "git rm public/index.html"
      File.append_at_line "#{path}/config/routes.rb",2,"  root :to => '#{root_resource}#index'"
    end

    define_step "show errors in production" do
      File.gsub "#{path}/config/environments/production.rb","config.consider_all_requests_local       = false","config.consider_all_requests_local       = true"
    end

    define_step "make error controller" do
      File.create "#{path}/app/controllers/tests_controller.rb","class TestsController < ApplicationController\n  def index; raise 'foo'; end\nend"
      File.append_at_line "#{path}/config/routes.rb",2,"resources :tests\n"
    end

    #define_step "make pow link" do
    #  run_cmd "ln -s #{path} /users/mharris717/.pow/#{name}"
    #end

    define_step "add to procfile" do
      File.append "#{path}/Procfile","rails: cd #{path} && rails server -p 5001\n"
    end

    define_step "restart" do
      run_cmd "touch tmp/restart.txt"
    end

    define_child_step "run plugins after", :after_plugins
  end

  class BaseDSL
    include FromHash
    fattr(:base) { Base.new }
    def method_missing(sym,*args,&b)
      base.send("#{sym}=",*args,&b)
    end
    def gem(*args)
      if args.last.kind_of?(Hash)
        base.gems << Gem.new(:name => args.first, :ops => args.last)
      else
        base.gems += args.map { |x| Gem.new(:name => x) }
      end
    end
    def resource(&b)
      dsl = ResourceDSL.new(:base => base)
      b[dsl]
      base.resources << dsl.resource
    end
    def seed(&b)
      dsl = ResourceDSL.new(:base => base, :resource => ResourceSeed.new(:base => base))
      b[dsl]
      base.resources << dsl.resource
    end
    def plugin(name)
      cls = eval("AppBuild::Plugin::#{name}")
      p = cls.new(:base => base)
      base.plugins << p
      yield(p) if block_given?
    end
  end
end