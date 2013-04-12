module AppBuild
  module SeedMod
    extend ActiveSupport::Concern

    included do
      define_step "seed data" do
        File.append "#{path}/db/seeds.rb","\n#{seed_str}\n\n"
      end
    end

    fattr(:seeds) { [] }

    def seed_str
      "#{class_name}.destroy_all\n" + seeds.join("\n")
    end

    def class_name
      name.to_s[0..0].upcase + name.to_s[1..-1]
    end
  end

  class Resource
    include FromHash
    include DefineStep
    include BaseRef
    attr_accessor :name, :base
    fattr(:columns) { [] }
    
    fattr(:relations) { [] }

    def opp_relations
      rels = base.resources.reject { |x| x == self }.map { |x| x.relations }.flatten
      rels.select { |x| x.other.to_s == name.to_s }.map { |x| x.opposite }
    end
    def full_relations
      relations + opp_relations
    end

    define_step "generate resource" do
      run_cmd "rails g resource #{name}"
    end

    def model_filename
      "#{path}/app/models/#{name}.rb"
    end
    define_step "add relations" do
      str = full_relations.map { |x| "  #{x}\n" }.join("")
      File.append_at_line model_filename,2,str
    end

    def column_str
      columns.map { |x| "      " + x.to_s }.join("\n").strip
    end
    def migration_filename
      Dir["#{path}/db/migrate/*.rb"].select { |x| x =~ /#{name}/ }.first
    end
    define_step "migration" do
      File.append_before migration_filename, "t.timestamps","#{column_str}\n      "
    end

    def controller_filename
      "#{path}/app/controllers/#{name}s_controller.rb"
    end
    define_step "setup controller" do
      File.gsub controller_filename, "ApplicationController","InheritedResources::Base\n  respond_to :html, :json"
    end

    define_step "add columns to serializer" do
      str = columns.map { |x| ",:#{x.name}" }.join("")
      serializer_filename = "#{path}/app/serializers/#{name}_serializer.rb"
      File.append_after serializer_filename, "attributes :id",str
    end

    define_step "default index template" do
      File.create "#{path}/app/views/#{name}s/index.html.haml","<h1>#{name} Index</h1>\nCount:\n= #{class_name}.count\n%br\nAll:\n- @#{name}s.each do |obj|\n  = obj.inspect\n  %br"
    end

    define_step "default show template" do
      File.create "#{path}/app/views/#{name}s/show.html.haml","<h1>#{name} Show</h1>\Data:\n= @#{name}.inspect"
    end

    include SeedMod
  end

  class ResourceSeed
    include DefineStep
    include BaseRef
    include SeedMod
    include FromHash
    attr_accessor :name, :base
    fattr(:relations) { [] }
  end

  

  class ResourceDSL
    include FromHash
    attr_accessor :base
    fattr(:resource) { Resource.new(:base => base) }
    def method_missing(sym,*args,&b)
      resource.send("#{sym}=",*args,&b)
    end
    def column(name,type)
      resource.columns << Column.new(:name => name, :type => type)
    end
    def columns(&b)
      res = ColumnDSL.new(:resource => resource)
      b[res]
    end
    def seed(ops)
      resource.seeds << Seed.new(:ops => ops, :resource => resource)
    end

    def belongs_to(other)
      resource.relations << Relation.new(:resource => resource, :type => :belongs_to, :other => other)
      resource.columns << Column.new(:name => "#{other}_id", :type => :references)
    end
  end
end