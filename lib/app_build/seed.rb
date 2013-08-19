module AppBuild
  class Seed
    include FromHash
    attr_accessor :ops, :resource

    def other_relation(k)
      #resource.base.resources.find { |x| x.name.to_s == k.to_s }
      resource.relations.find { |x| x.other_name.to_s == k.to_s }
    end
    def ops_str
      res = []
      ops.each do |k,v|
        other = other_relation(k)
        if other
          res << ":#{k} => #{other.other_resource.class_name}.where(#{v.to_s_as_ops[1..-1]}).first"
        else
          v = standard_value_rep(k,v)
          res << ":#{k} => #{v}"
        end
      end
      res.join(", ")
    end

    def standard_value_rep(k,v)
      col_type = if !resource.respond_to?(:columns)
        nil
      else
        resource.columns.find { |x| x.name.to_s == k.to_s }.type
      end
      if col_type.to_s == 'datetime'
        "Time.local(#{v.join(",")})"
      elsif v.kind_of?(String)
        "'#{v}'"
      else
        v
      end
    end

    def to_s
      "#{resource.class_name}.create!(#{ops_str})"
    end
  end
end