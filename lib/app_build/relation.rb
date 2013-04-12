module AppBuild
  class Relation
    include FromHash
    attr_accessor :resource, :type, :other

    def to_s
      arg = other.to_s
      arg += "s" if type == :has_many
      "#{type} :#{arg}"
    end

    def other_resource
      resource.base.resources.find { |x| x.name.to_s == other.to_s }
    end
    def opp_type
      h = {:belongs_to => :has_many, :has_many => :belongs_to}
      h[type] || (raise "bad type #{type}")
    end

    def opposite
      Relation.new(:resource => other_resource, :type => opp_type, :other => resource.name)
    end
  end
end