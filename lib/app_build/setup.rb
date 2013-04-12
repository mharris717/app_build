puts "Start #{Time.now}"

require 'mharris_ext'
require 'active_support'
require 'fileutils'

require "redis"
require 'yaml'



def redis
  $redis ||= Redis.new
end
def clear_redis!(name=nil)
  redis.keys.each do |k|
    if name
      redis.del k if k =~ /#{name}/i
    else
      redis.del k
    end
  end
end

clear_redis! if ARGV[0] == 'clear'