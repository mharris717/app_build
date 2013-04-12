class Hash
  def naked_inspect
    inspect[1..-2]
  end
  def to_s_as_ops
    empty? ? "" : ",#{naked_inspect}"
  end
end

class File
  class << self
    def gsub(filename,a,b)
      #puts "gsub file #{filename}"
      str = read(filename)
      str = str.gsub(a,b)
      File.create filename,str
    end
    def append_before(filename,find,rep)
      full = "#{rep}#{find}"
      gsub(filename,find,full)
    end
    def append_after(filename,find,rep)
      full = "#{find}#{rep}"
      gsub(filename,find,full)
    end
    def append_at_line(filename,num,str)
      num -= 1
      lines = File.read(filename).split("\n")
      lines = lines[0...num] + [str] + lines[num..-1]
      File.create filename, lines.join("\n")
    end
    def prepend(filename,str)
      str = str + File.read(filename)
      File.create filename,str
    end
  end
end

class Object
  def blank?
    to_s.strip == ''
  end
  def present?
    !blank?
  end
end