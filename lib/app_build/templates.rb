module AppBuild
  class Templates
    class << self
      def get(name)
        full = File.dirname(__FILE__) + "/templates/#{name}"
        File.read full
      end
    end
  end
end