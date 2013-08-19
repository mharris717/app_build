namespace :db do
  namespace :schema do
    desc 'Regenerate the Ember schema.js based on the serializers'
    task :ember => :environment do
      schema_hash = {}
      Rails.application.eager_load! # populate descendants
      ActiveModel::Serializer.descendants.sort_by(&:name).each do |serializer_class|
        schema = serializer_class.schema
        schema_hash[serializer_class.model_class.name] = schema
      end

      schema_json = JSON.pretty_generate(schema_hash)
      File.open 'db/schema.js', 'w' do |f|
        f << "// Model schema, auto-generated from serializers.\n"
        f << "// This file should be checked in like db/schema.rb.\n"
        f << "// Check lib/tasks/ember_schema.rake for documentation.\n"
        f << "window.serializerSchema = #{schema_json}\n"
      end
    end
  end
end