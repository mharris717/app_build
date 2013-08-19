module AppBuild
  class Column
    include FromHash
    attr_accessor :name, :type
    fattr(:ops) { {} }

    def to_s
      col = (type == :references) ? name.to_s[0..-4] : name
      "t.#{type} :#{col}#{ops.to_s_as_ops}"
    end
  end

  class ColumnDSL
    include FromHash
    attr_accessor :resource

    %w(string integer datetime).each do |col|
      define_method(col) do |name,ops={}|
        resource.columns << Column.new(:name => name, :type => col, :ops => ops)
      end
    end
  end
end