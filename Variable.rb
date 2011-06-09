class Variable
  @@argumentIndex = 0
  @@localIndex = 0
  @@staticIndex = 0
  @@fieldIndex = 0
  
  def initialize(name , type , kind)
    @name = name
    @type = type
    @kind = kind
    
    case kind
    when "local"
      @index = @@localIndex
      @@localIndex += 1
    when "argument"
      @index = @@argumentIndex
      @@argumentIndex += 1
    when "static"
      @index = @@staticIndex
      @@staticIndex += 1
    when "field"
      @index = @@fieldIndex
      @@fieldIndex += 1
    end
  end
  
  def getType
    return @type
  end
  
  def getDescriptor
    return @kind
  end
  
  def getIndex
    return @index
  end
  
  def getName
    return @name
  end
  
  #def to_s  
  #end
end