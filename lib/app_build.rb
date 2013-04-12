%w(ext setup step base resource column gem relation seed plugin).each do |f|
  load File.dirname(__FILE__) + "/app_build/#{f}.rb"
end

%w(active_admin airbrake auth ember error_reporting heroku).each do |f|
  load File.dirname(__FILE__) + "/app_build/plugin/#{f}.rb"
end

module AppBuild
  class << self
    def build(&b)
      res = BaseDSL.new
      b[res]
      res.base.run!
    end
  end
end

