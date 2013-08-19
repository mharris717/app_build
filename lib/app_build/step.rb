module AppBuild
  class Step
    include FromHash
    attr_accessor :name, :block, :parent, :type
    fattr(:skip) { true }
    def run_once!(obj)
      puts "Running #{name}"
      obj.instance_eval(&block)
    end

    def dry_run?
      false
    end

    def run!(obj)
      k = key(obj)
      if dry_run?
        puts "Step #{k.inspect}"
        run_once!(obj) if type == :children
      elsif redis.get(k) && skip
        puts "Skipping #{k}"
      else
        run_once!(obj)
        redis.set k,true
        commit! obj
      end
    end

    def commit!(obj)
      return if obj.git("status", :silent => true, :path => :container) =~ /nothing to commit/
      k = key(obj)
      obj.git "add .", :silent => true
      obj.git "commit -m \"#{k}\"", :silent => true
    end

    def key(obj)
      "#{parent}-#{obj.name}-#{name}"
    end

  end

  module DefineStep
    extend ActiveSupport::Concern
    module ClassMethods
      fattr(:steps) { {} }
      def define_step(name,ops={},&b)
        ops = ops.merge(:name => name, :block => b, :parent => self)
        steps[name] = Step.new(ops)
      end
      def run_steps!(obj)
        steps.values.each do |step|
          step.run!(obj)
        end
      end

      def define_child_step(name,arr_name)
        b = lambda do |o|
          puts "sending #{arr_name}"
          a = o.send(arr_name)
          a.each { |x| x.run! }
        end
        define_step(name, {:skip => false, :type => :children}, &b)
      end
    end
    def run!
      self.class.run_steps!(self)
    end

    def self.included(mod)
      super
      mod.steps!
    end
  end
end