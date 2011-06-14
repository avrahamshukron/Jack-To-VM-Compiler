class Variable
  @@argumentIndex = 0
  @@localIndex = 0
  @@staticIndex = 0
  @@fieldIndex = 0
  
  def self.argumentIndex=(arg)
    @@argumentIndex = arg
  end
  
  def self.argumentIndex
    @@argumentIndex
  end
  
  def self.fieldIndex=(fld)
      @@fieldIndex = fld
  end
  def self.fieldIndex
    @@fieldIndex
  end
  
  def self.staticIndex=(stt)
     @@staticIndex = stt
  end
  def self.staticIndex
    @@staticIndex
  end
  
  def self.localIndex=(lcl)
        @@localIndex = lcl
  end
  def self.localIndex
    @@localIndex
  end
  
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
  
  def type=(aType)
    @type = aType
  end
  def type
      @type
  end
  
  def kind=(aKind)
    @kind = aKind
  end
  def kind
    @kind
  end
  
  def index=(aIndex)
    @index = index
  end
  def index
    @index
  end  
  
  def name=(aName)
    @name = aName
  end
  def name
    @name
  end
  #def to_s  
  #end
end