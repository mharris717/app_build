module AppBuild
  module Plugin
    class Base
      include DefineStep
      include BaseRef
      include FromHash
      attr_accessor :base
      def lifecycle; :main; end


      def pre!
        base.gems += self.class.gems
      end

      class << self
        def gem(name,*args)
          ops = args.last.kind_of?(Hash) ? args.pop : {}
          version = args.last
          gems << Gem.new(:name => name, :version => version, :ops => ops)
        end
        fattr(:gems) { [] }
      end
    end
  end
end