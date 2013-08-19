module AppBuild
  class Relation
    include FromHash
    attr_accessor :resource, :type, :other, :other_prefix
    def other_name
      other_prefix ? "#{other_prefix}_#{other}" : other
    end
    def column_name
      "#{other_name}_id"
    end

    def to_s
      arg = other_name.to_s
      arg += "s" if type == :has_many
      res = "#{type} :#{arg}"
      if other_prefix
        res << ", :class_name => '#{other_resource.class_name}'"
      end
      res
    end

    def other_resource
      resource.base.resources.find { |x| x.name.to_s == other.to_s }
    end
    def opp_type
      h = {:belongs_to => :has_many, :has_many => :belongs_to}
      h[type] || (raise "bad type #{type}")
    end

    def opposite
      Relation.new(:resource => other_resource, :type => opp_type, :other => resource.name, :other_prefix => other_prefix)
    end
  end
end