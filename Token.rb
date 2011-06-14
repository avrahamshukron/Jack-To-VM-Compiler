#######################################################################
#               Principles Of Programming Languages
#   By:
#     Avraham Shukron, ID 301827267
#     Yshai Levenglick, ID
#######################################################################


#######################################################################
#                         Token Class
# Represents a token element in the language.
# Defined by the couple of Token Type and the Lexeme Value
#######################################################################
class Token
  
  @type
  @value
  
  def initialize(aType)
    @type = aType;
    @value = nil;
  end
  
  def initialize(aType , aValue)
    @type = aType;
    @value = aValue;
  end
  
  
  def getType
    return @type
  end
  def type
    @type
  end
  def type=(t)
    @type=t
  end
  
  def value
    @value
  end
  def value=(v)
    @value=v
  end
  def getValue
    return @value
  end
 
  def to_s
    value = @value
    value.gsub!(/[><&\/"']/,"&gt;")
    return "<" + @type.to_s() + ">" + value.to_s() + "</" + @type.to_s() + ">"
  end
end


class TokenType
  INTEGER_CONSTANT = "IntegerConstant"
  STRING_LITERAL = "StringLiteral"
  KEYWORD = "Keyword"
  STATEMENTS = "StatementType"
  CONSTANT_VALUE_KEYWORD = "ConstantsKeyword"
  UNARY_OPERATOR = "UnaryOperator"
  BINARY_OPERATOR = "BinaryOperator"
  SUBRUTINE_DESCRIPTOR = "SubrutineDescriptor"
  CLASS_VAR_DESCRIPTOR = "ClassVariableDescriptor"
  SEMICOLON = "SemiColon"
  COMMA = "Comma"
  PRIMITIVE_TYPE = "PrimitiveType"
  SYMBOL = "Symbol"
  IDENTIFIER = "Identifier"
  TOKEN_ERROR = "Error"
  SYNTAX_ERROR = "SyntaxError"
end