require 'Token.rb'
require 'State.rb'

class JackTokenizer
  @document = []  
  RESERVED_WORDS = ['class','var','void','else']
  STATEMENTS = ['while','return','let','do','if']
  STOP_SYMBOLS = [" ","\n","\t"]
  RESERVED_SYMBOLS = ['(',')','{','}','.','[',']']
  SEMICOLON = ";"
  COMMA = ","
  PRIMITIVE_TYPE = ['int','char','boolean']
  SUBRUTINE_DESCRIPTOR = ['costructor','function','method']
  CONSTANT_VALUE_KEYWORD = ['true','false','null','this'] 
  CLASS_VAR_DESCRIPTOR = ['field','static']
  UNARY_OPERATOR = ['-','~']
  BINARY_OPERATOR = ['*','+','=','&','|','>','<']
    
  def initialize(inputFilePath)
    @input = File.open(inputFilePath,"r")
    @output = File.open("TokenStream.xml","w")
    @document = @input.read().split(//)
    @currentState = State::START_STATE
    @currentChar = ""
    @currentWord = ""
  end
  
  def printDoc
    print @document
  end
  
  def readNextChar
    @currentChar = @document[0]
    #print "Now Read: \"" + @currentChar + "\"\n"
    @document.delete_at(0)
  end
  
  def confirmChar()
    if @currentWord
      @currentWord += @currentChar.to_str()
    elsif @currentChar
      @currentWord = @currentChar
    end
    @currentChar = nil
  end
  
  def skipChar
    @currentChar = nil
  end
  
  def isReservedSymbol(symbol)
    return (RESERVED_SYMBOLS.include?(symbol))
  end
  
  def isBinaryOperator(symbol)
    return BINARY_OPERATOR.include?(symbol)
  end
  
  def isUnaryOperator(symbol)
    return UNARY_OPERATOR.include?(symbol) 
  end
  
  def getCurrentChar
    if (@currentChar == nil || @currentChar == "")
      @currentChar = readNextChar()
    end
    return @currentChar
  end
  
  def isKeyword(word)
    return RESERVED_WORDS.include?(word)
  end
  
  def isStopSymbol(symbol)
    return STOP_SYMBOLS.include?(symbol)
  end
  
  def shouldStopToken(symbol)
    return (isStopSymbol(symbol) || isReservedSymbol(symbol)||
              symbol == SEMICOLON || isBinaryOperator(symbol) || 
              isUnaryOperator(symbol) || symbol == COMMA) 
  end
  
  def clearCurrentWord
    @currentWord = ""
  end
  
  def printToken(token)
    @output.write(token.to_s()+"\n")
  end
  
  def startState(input)
    clearCurrentWord()
    ###################### End of Token ###################################
     if shouldStopToken(input)
       if isReservedSymbol(input)
         confirmChar()
         printToken(Token.new(TokenType::SYMBOL,@currentWord))
       elsif isBinaryOperator(input)
         confirmChar()
         printToken(Token.new(TokenType::BINARY_OPERATOR,@currentWord))
       elsif isUnaryOperator(input)
         confirmChar()
         @output.write(Token.new(TokenType::UNARY_OPERATOR,@currentWord))
       elsif input == SEMICOLON
         confirmChar()
         printToken(Token.new(TokenType::SEMICOLON,@currentWord))
       elsif input == COMMA
         confirmChar()
         printToken(Token.new(TokenType::COMMA,@currentWord))
       else
         skipChar()
       end
     ###################### Not end of Token ###################################
     elsif input == "\""
       skipChar()
       @currentState = State::STRING_STATE
     elsif input =~ /[a-z]/
       confirmChar()
       @currentState = State::KEYWORD_APP_STATE
     elsif input =~ /[A-Z_]/
       confirmChar()
       @currentState = State::ID_STATE
     elsif input == "/"
       confirmChar()
       @currentState = State::SLASH_STATE
     elsif input =~ /[1-9]/
       confirmChar()
       @currentState = State::NUM_STATE
     elsif input == '0'
       confirmChar()
       @currentState = State::ZERO_STATE
     else 
       confirmChar()
       @currentState = State::ERROR_STATE
     end
  end
  
  def zeroState(input)
    if shouldStopToken(input)
       @currentState = State::START_STATE
       printToken(Token.new(TokenType::INTEGER_CONSTANT, @currentWord))
    else
       confirmChar()
       @currentState = State::ERROR_STATE
    end
  end
  
  def stringState(input)
    if (input == "\"")
      skipChar()
      @currentState = State::START_STATE
      printToken(Token.new(TokenType::STRING_LITERAL, @currentWord))
    else
      confirmChar()
    end
  end
  
  def numState(input)
    if input =~ /\d/
       confirmChar()
     elsif shouldStopToken(input)
       @currentState = State::START_STATE
       printToken(Token.new(TokenType::INTEGER_CONSTANT, @currentWord))
     else
       confirmChar()
       @currentState = State::ERROR_STATE
     end
  end
  
  def keywordAppState(input)
    if input =~ /[a-z]/
      confirmChar()
    elsif shouldStopToken(input)
      @currentState = State::START_STATE
      if isKeyword(@currentWord)
        printToken(Token.new(TokenType::KEYWORD, @currentWord))
      elsif PRIMITIVE_TYPE.include?(@currentWord)
        printToken(Token.new(TokenType::PRIMITIVE_TYPE, @currentWord))
      elsif SUBRUTINE_DESCRIPTOR.include?(@currentWord)
        printToken(Token.new(TokenType::SUBRUTINE_DESCRIPTOR, @currentWord))
      elsif CLASS_VAR_DESCRIPTOR.include?(@currentWord)
        printToken(Token.new(TokenType::CLASS_VAR_DESCRIPTOR, @currentWord))
      elsif CONSTANT_VALUE_KEYWORD.include?(@currentWord)
        printToken(Token.new(TokenType::CONSTANT_VALUE_KEYWORD, @currentWord))
      elsif STATEMENTS.include?(@currentWord)
        printToken(Token.new(TokenType::STATEMENTS, @currentWord))
      else
        printToken(Token.new(TokenType::IDENTIFIER, @currentWord))
      end   
    else
      confirmChar()
      @currentState = State::ID_STATE
    end 
  end
 
  def idState(input)
    if shouldStopToken(input)
      @currentState = State::START_STATE
      printToken(Token.new(TokenType::IDENTIFIER,@currentWord))
    else
      confirmChar()
    end    
  end 
  
  def slashState(input)
    if (input == "*")
      skipChar()
      @currentState = State::COMMENT_LONG_STATE
    elsif (input == "/")
      skipChar()
      @currentState = State::COMMENT_SINGLE_STATE
    else
      @currentState = State::START_STATE
      printToken(Token.new(TokenType::BINARY_OPERATOR, @currentWord))
    end  
  end
  
  def singleLineCommentState(input)
    if input == "\n"
      @currentState = State::START_STATE
    end  
    skipChar()
  end
  
  def multilineCommentState(input)
    if input == '*'
      confirmChar()
      @currentState = State::COMMENT_LONG_EXIT_APP_STATE
    else
      skipChar()
    end  
  end
  
  def multilineCommentExitState(input)
    if input == '/'
      @currentState = State::START_STATE
    else
      @currentState = State::COMMENT_LONG_STATE
    end
    skipChar()
  end
  
  def errorState(input)
    if shouldStopToken(input)
      @currentState = State::START_STATE
      printToken(Token.new(TokenType::TOKEN_ERROR,@currentWord))
    else
      confirmChar()
    end 
  end
  ##############################################################
  #     Tokenize the jack 
  ##############################################################
   def Tokenize
     #@output.write("<?xml version=\"1.0\"?>\n")
     @output.write("<TokenStream>\n")
     while (@document.length > 0)
       input = getCurrentChar()
       case @currentState
         #############################################################
         when State::START_STATE
           startState(input)
         #############################################################
         when State::STRING_STATE
           stringState(input)
         #############################################################
         when State::ZERO_STATE
           zeroState(input)
         ##############################################################
         when State::NUM_STATE
           numState(input)
         ###############################################################
         when State::KEYWORD_APP_STATE
           keywordAppState(input)
         ################################################################
         when State::ID_STATE
           idState(input)
        ##################################################################
         when State::SLASH_STATE
           slashState(input)   
        ##################################################################
         when State::COMMENT_SINGLE_STATE
           singleLineCommentState(input)
        ####################################################################
         when State::COMMENT_LONG_STATE
           multilineCommentState(input)
        ####################################################################
         when State::COMMENT_LONG_EXIT_APP_STATE
           multilineCommentExitState(input)
        ####################################################################
         when State::ERROR_STATE
           errorState(input)
        #####################################################################
       end
     end
     @output.write("</TokenStream>\n")
  end
  
  def getCurrentToken
    toReturn = nil
    while (@document.length > 0 && toReturn == nil)
      input = getCurrentChar()
      case @currentState
         #############################################################
         when State::START_STATE
           clearCurrentWord()
           if shouldStopToken(input)
             if isReservedSymbol(input)
               confirmChar()
               toReturn = Token.new(TokenType::SYMBOL,@currentWord)
             elsif isBinaryOperator(input)
               confirmChar()
               toReturn = (Token.new(TokenType::BINARY_OPERATOR,@currentWord))
             elsif isUnaryOperator(input)
               confirmChar()
               toReturn = (Token.new(TokenType::UNARY_OPERATOR,@currentWord))
             elsif input == SEMICOLON
               confirmChar()
               toReturn = (Token.new(TokenType::SEMICOLON,@currentWord))
             elsif input == COMMA
               confirmChar()
               toReturn = (Token.new(TokenType::COMMA,@currentWord))
             else
               skipChar()
             end
           elsif input == "\""
             skipChar()
             @currentState = State::STRING_STATE
           elsif input =~ /[a-z]/
             confirmChar()
             @currentState = State::KEYWORD_APP_STATE
           elsif input =~ /[A-Z_]/
             confirmChar()
             @currentState = State::ID_STATE
           elsif input == "/"
             confirmChar()
             @currentState = State::SLASH_STATE
           elsif input =~ /[1-9]/
             confirmChar()
             @currentState = State::NUM_STATE
           elsif input == '0'
             confirmChar()
             @currentState = State::ZERO_STATE
           else
             confirmChar()
             @currentState = State::ERROR_STATE
           end
             #############################################################
         when State::STRING_STATE
           if (input == "\"")
             skipChar()
             @currentState = State::START_STATE
             toReturn = (Token.new(TokenType::STRING_LITERAL, @currentWord))
           else
             confirmChar()
           end
         #############################################################
         when State::ZERO_STATE
           if shouldStopToken(input)
             @currentState = State::START_STATE
             toReturn = (Token.new(TokenType::INTEGER_CONSTANT, @currentWord))
           else
             confirmChar()
             @currentState = State::ERROR_STATE
           end
         ##############################################################
         when State::NUM_STATE
           if input =~ /\d/
             confirmChar()
           elsif shouldStopToken(input)
             @currentState = State::START_STATE
             toReturn = (Token.new(TokenType::INTEGER_CONSTANT, @currentWord))
           else
             confirmChar()
             @currentState = State::ERROR_STATE
           end
         ###############################################################
         when State::KEYWORD_APP_STATE
           if input =~ /[a-z]/
             confirmChar()
           elsif shouldStopToken(input)
             @currentState = State::START_STATE
             if isKeyword(@currentWord)
               toReturn = (Token.new(TokenType::KEYWORD, @currentWord))
             elsif PRIMITIVE_TYPE.include?(@currentWord)
               toReturn = (Token.new(TokenType::PRIMITIVE_TYPE, @currentWord))
             elsif SUBRUTINE_DESCRIPTOR.include?(@currentWord)
               toReturn = (Token.new(TokenType::SUBRUTINE_DESCRIPTOR, @currentWord))
             elsif CLASS_VAR_DESCRIPTOR.include?(@currentWord)
               toReturn = (Token.new(TokenType::CLASS_VAR_DESCRIPTOR, @currentWord))
             elsif CONSTANT_VALUE_KEYWORD.include?(@currentWord)
               toReturn = (Token.new(TokenType::CONSTANT_VALUE_KEYWORD, @currentWord))
             elsif STATEMENTS.include?(@currentWord)
               toReturn = (Token.new(TokenType::STATEMENTS, @currentWord))
             else
               toReturn = (Token.new(TokenType::IDENTIFIER, @currentWord))
             end   
           else
             confirmChar()
             @currentState = State::ID_STATE
           end
         ################################################################
         when State::ID_STATE
           if shouldStopToken(input)
             @currentState = State::START_STATE
             toReturn = (Token.new(TokenType::IDENTIFIER,@currentWord))
           else
             confirmChar()
           end
        ##################################################################
         when State::SLASH_STATE
           if (input == '*')
             skipChar()
             @currentState = State::COMMENT_LONG_STATE
           elsif (input == '/')
             skipChar()
             @currentState = State::COMMENT_SINGLE_STATE
           else
             @currentState = State::START_STATE
             toReturn = (Token.new(TokenType::BINARY_OPERATOR, @currentWord))
           end
        ##################################################################
       when State::COMMENT_SINGLE_STATE
         if input == "\n"
           @currentState = State::START_STATE
         else
           skipChar()
         end
       ####################################################################
       when State::COMMENT_LONG_STATE
         if input == '*'
           confirmChar()
           @currentState = State::COMMENT_LONG_EXIT_APP_STATE
         else
           skipChar()
         end
      ####################################################################
       when State::COMMENT_LONG_EXIT_APP_STATE
         if input == '/'
           @currentState = State::START_STATE
         else
           @currentState = State::COMMENT_LONG_STATE
         end
         skipChar()
      ####################################################################
       when State::ERROR_STATE
         if shouldStopToken(input)
           @currentState = State::START_STATE
           toReturn = (Token.new(TokenType::TOKEN_ERROR,@currentWord))
         else
           confirmChar()
         end 
      #####################################################################
      end
    end
    return toReturn
  end
  
##### End Class ##############
end
