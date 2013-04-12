module AppBuild
  class Gem
    include FromHash
    attr_accessor :name, :version
    fattr(:ops) { {} }

    def to_s
      v = version.present? ? ",'#{version}'" : ""
      "gem '#{name}'#{v}#{ops.to_s_as_ops}"
    end
  end
end