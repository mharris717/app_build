module AppBuild
  class Seed
    include FromHash
    attr_accessor :ops, :resource

    def other_resource(k)
      resource.base.resources.find { |x| x.name.to_s == k.to_s }
    end
    def ops_str
      res = []
      ops.each do |k,v|
        other = other_resource(k)
        if other
          res << ":#{k} => #{other.class_name}.where(#{v.to_s_as_ops[1..-1]}).first"
        else
          v = "'#{v}'" if v.kind_of?(String)
          res << ":#{k} => #{v}"
        end
      end
      res.join(", ")
    end

    def to_s
      "#{resource.class_name}.create!(#{ops_str})"
    end
  end
end