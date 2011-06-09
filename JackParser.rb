require "Token.rb"
require "JackTokenizer.rb"
require "Variable.rb"
class JackParser
  
  def initialize(sourceCodeFilePath)
    @output = File.open("ParseTree.xml","w")
    @currentToken = nil
    @tokenizer = JackTokenizer.new(sourceCodeFilePath)
    @indentation = -1
    
    @classSymbolTable = Hash.new()
    @methodSymbolTable = Hash.new()
  end
  
  def printToFile(text)
    indent()
    @output.write(text + "\n")
  end
  
  def openTag(tag)
    printToFile("<"+tag+">")
    @indentation += 1
  end
  
  def closeTag(tag)
    @indentation -= 1
    printToFile("</"+tag+">")
  end
  
  def start
    classDeclaration()
    puts @classSymbolTable.empty?()
    puts @classSymbolTable.inspect()
    puts @classSymbolTable.size()
    
    puts @methodSymbolTable.inspect()
  end
  
  def indent
    for i in 0..@indentation
      @output.write("\t")
    end
  end
  
  def printParseErrorMessage(message)
    printToFile(Token.new(TokenType::SYNTAX_ERROR , message).to_s())
  end
  
  def readNextToken
    @currentToken = @tokenizer.getCurrentToken()
  end
  
  def printTokenAndReadNext
    printToFile(@currentToken.to_s())
    readNextToken()
  end
  
  def matchingSymbol(name)
    if @methodSymbolTable.include?(name)
      return @methodSymbolTable[name]
    elsif @classSymbolTable.include?(name)
      return @classSymbolTable[name]
    else 
      return nil
    end
  end
  
  def insertToSymbolTable(name,type,kind)
    case kind
        when "local" , "argument"
          if ! @classSymbolTable.include?(name) 
            @methodSymbolTable.store(name,Variable.new(name,type,kind))
          else
          end
        when "static" ,"field"
          if ! @methodSymbolTable.include?(name)
            @classSymbolTable.store(name,Variable.new(name,type,kind))
          else
          end
    end
  end
  
  def classDeclaration
    openTag("ClassDeclaration")
    readNextToken()
    if @currentToken.getValue == "class"
      printTokenAndReadNext()
      if @currentToken.getType == TokenType::IDENTIFIER
        printTokenAndReadNext()
        if @currentToken.getValue == "{"
          printTokenAndReadNext()
          classVarDecList()
          subrutineDecList()
          if @currentToken.getValue() == "}"
            printTokenAndReadNext()
          else
            printParseErrorMessage("Expected \"}\"")
          end
        else
          printParseErrorMessage("Expected \"{\"")
        end
      else
        printParseErrorMessage("Expected Identifier")
      end
    else
      printParseErrorMessage("Expected \"class\"")
    end
    closeTag("ClassDeclaration")
  end
  
  def classVarDec
    openTag("ClassVariablesDeclaration")
      if @currentToken.getType == TokenType::CLASS_VAR_DESCRIPTOR
        kind = @currentToken.getValue()
        printTokenAndReadNext()
        type = type()
        idList(type , kind)
        if @currentToken.getType == TokenType::SEMICOLON
          printTokenAndReadNext()
        else
          printParseErrorMessage("missing \";\"?")
        end
      else
        printParseErrorMessage("Expected classVarDescriptor")
      end
    closeTag("ClassVariablesDeclaration")
  end
    
  def classVarDecList
    openTag("ClassVarDeclarationList")
    if @currentToken.getType == TokenType::CLASS_VAR_DESCRIPTOR
      classVarDec()
      classVarDecList()
    end
    closeTag("ClassVarDeclarationList")
  end
  
  def subrutineDecList()
    openTag("SubrutineDeclarationList")
    if (@currentToken.getType == TokenType::SUBRUTINE_DESCRIPTOR)
      subrutineDec()
      subrutineDecList()
    end
    closeTag("SubrutineDeclarationList")
  end
  
  def idList(type , kind)
    openTag("idList")
    if @currentToken.getType == TokenType::IDENTIFIER
      name = @currentToken.getValue()
      insertToSymbolTable(name,type,kind)
      printTokenAndReadNext()
      idListCont()
    else
      printParseErrorMessage("Expected identifier")
    end
    closeTag("idList")
  end
    
  def idListCont
    openTag("idListCont")
    if @currentToken.getType == TokenType::COMMA
      printTokenAndReadNext()
      idList()
    end
    closeTag("idListCont")
  end
  
  def type
    openTag("Type")
    toReturn = nil
    if (@currentToken.getType == TokenType::PRIMITIVE_TYPE || 
        @currentToken.getType == TokenType::IDENTIFIER)
      toReturn = @currentToken.getValue()
      printTokenAndReadNext()
    else
      printParseErrorMessage("Expected a type")
    end
    closeTag("Type")
    return toReturn
  end
  
  def subrutineDec
    openTag("SubrutineDeclaration")
    if (@currentToken.getType == TokenType::SUBRUTINE_DESCRIPTOR)    
      printTokenAndReadNext()
      returnType()
      if @currentToken.getType == TokenType::IDENTIFIER
        printTokenAndReadNext()
        if @currentToken.getValue == "("
          printTokenAndReadNext()
          parameterList()
          if @currentToken.getValue == ")"
            printTokenAndReadNext()
            subrutineBody()
          else
            printParseErrorMessage("Expected \")\"")
          end
        else
          printParseErrorMessage("Expected \"(\"")
        end
      else
        printParseErrorMessage("Expected identifier")
      end
    else
      printParseErrorMessage("Expected subrutine descriptor")
    end
    closeTag("SubrutineDeclaration")
  end
  
  def returnType
    openTag("ReturnType")
    if @currentToken.getValue == "void"
      printTokenAndReadNext() 
    else
      type()
    end
    closeTag("ReturnType")
  end
  
  def parameterList
    openTag("ParametersList")
    if (@currentToken.getType == TokenType::IDENTIFIER ||
       @currentToken.getType == TokenType::PRIMITIVE_TYPE)
      paramDec()
      paramListCont()
    end
    closeTag("ParametersList")
  end
  
  def paramListCont()
    openTag("ParametersListCont")
    if @currentToken.getType == TokenType::COMMA
      printTokenAndReadNext()
      parameterList()
    end
    closeTag("ParametersListCont")
  end
  
  def paramDec()
    openTag("ParameterDeclaration")
    type()
    if @currentToken.getType == TokenType::IDENTIFIER
      printTokenAndReadNext()
    else
      printParseErrorMessage("Expected identifier")
    end
    closeTag("ParameterDeclaration")
  end
  
  def subrutineBody
    openTag("SubrutineBody")
    if @currentToken.getValue == "{"
      printTokenAndReadNext()
      varDeclarationList()
      statements()
      if @currentToken.getValue == "}"
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \"}\"")
      end
    else
      printParseErrorMessage("Expected \"{\"")
    end
    closeTag("SubrutineBody")
  end
  
  def varDeclarationList()
    openTag("VarDeclarationList")
    if @currentToken.getValue == "var"
      varDeclaration()
      varDeclarationList()
    end
    closeTag("VarDeclarationList")
  end
  
  def varDeclaration()
    openTag("VarDeclaration")
    if @currentToken.getValue == "var"
      printTokenAndReadNext()
      type = type()
      idList(type , "local")
      if @currentToken.getType == TokenType::SEMICOLON
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \";\"")
      end
    else
      printParseErrorMessage("Expected \"var\"")
    end
    closeTag("VarDeclaration")
  end
  
  def statements()
    openTag("Statements")
    if @currentToken.getType == TokenType::STATEMENTS
      singleStatement()
      statements()
    end
    closeTag("Statements")
  end

  def singleStatement
    openTag("SingleStatement")
    case @currentToken.getValue
    when "let"
      letStatement()
    when "do"
      doStatement()
    when "if"
      ifStatement()
    when "while"
      whileStatement()
    when "return"
      returnStatement()
    else 
      printParseErrorMessage("Expected valid statement")
    end
    closeTag("SingleStatement")
  end

  def atIndex
    openTag("AtIndex")
    if @currentToken.getValue == "["
      printTokenAndReadNext()
      expression()
      if @currentToken.getValue == "]"
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \"]\"")
      end
    end
    closeTag("AtIndex")
  end
  
  def letStatement
    openTag("LetStatement")
    if @currentToken.getValue == "let"
      printTokenAndReadNext()
      if @currentToken.getType == TokenType::IDENTIFIER
        printTokenAndReadNext()
        atIndex()
        if @currentToken.getValue == "="
          printTokenAndReadNext()
          expression()
          if @currentToken.getType == TokenType::SEMICOLON
            printTokenAndReadNext()
          else
            printParseErrorMessage("Expected \";\"")
          end
        else
          printParseErrorMessage("Expected \"=\"")
        end
      else
        printParseErrorMessage("Expected identifier")
      end
    else
      printParseErrorMessage("Expected \"let\"")
    end
    closeTag("LetStatement")
  end
  
  def doStatement
    openTag("DoStatement")
      if @currentToken.getValue == "do"
        printTokenAndReadNext()
        subrutineCall()
        if @currentToken.getType == TokenType::SEMICOLON
          printTokenAndReadNext()
        else
          printParseErrorMessage("Expected \";\"")
        end
      else
        printParseErrorMessage("Expected \"do\"")
      end
    closeTag("DoStatement")
  end
  
  def ifStatement
    openTag("IfStatement")
    if @currentToken.getValue == "if"
      printTokenAndReadNext()
      if @currentToken.getValue == "("
        printTokenAndReadNext()
        expression()
        if @currentToken.getValue == ")"
          printTokenAndReadNext()
          if @currentToken.getValue == "{"
            printTokenAndReadNext()
            statements()
            if @currentToken.getValue == "}"
              printTokenAndReadNext()
              elseStatement()
            else
              printParseErrorMessage("Expected \"}\"")
            end
          else
            printParseErrorMessage("Expected \"{\"")
          end
        else
          printParseErrorMessage("Expected \")\"")
        end
      else
        printParseErrorMessage("Expected \"(\"")
      end
    else
      printParseErrorMessage("Expected \"if\"")
    end
    closeTag("IfStatement") 
  end
  
  def elseStatement
    openTag("ElseStatement")
    if @currentToken.getValue == "else"
      printTokenAndReadNext()
      if @currentToken.getValue == "{"
        printTokenAndReadNext()
        statements()
        if @currentToken.getValue == "}"
          printTokenAndReadNext()
        else
          printParseErrorMessage("Expected \"}\"")
        end
      else
        printParseErrorMessage("Expected \"{\"")
      end
    else
      printParseErrorMessage("Expected \"else\"")
    end
    closeTag("ElseStatement")
  end
  
  def whileStatement
    openTag("WhileStatement")
    if @currentToken.getValue == "while"
      printTokenAndReadNext()
      if @currentToken.getValue == "("
        printTokenAndReadNext()
        expression()
        if @currentToken.getValue == ")"
          printTokenAndReadNext()
          if @currentToken.getValue == "{"
            printTokenAndReadNext()
            statements()
            if @currentToken.getValue == "}"
              printTokenAndReadNext()
            else
              printParseErrorMessage("Expected \"}\"")
            end
          else
            printParseErrorMessage("Expected \"{\"")
          end
        else
          printParseErrorMessage("Expected \")\"")
        end
      else
        printParseErrorMessage("Expected \"(\"")
      end
    else
      printParseErrorMessage("Expected \"while\"")
    end
    closeTag("WhileStatement")
  end
  
  def returnStatement
    openTag("ReturnStatement")
    if @currentToken.getValue == "return"
      printTokenAndReadNext()
      expressionOrVoid()
      if @currentToken.getType == TokenType::SEMICOLON
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \";\"")
      end
    else
      printParseErrorMessage("Expected \"return\"")
    end
    closeTag("ReturnStatement")
  end
  
  def subrutineCall
    openTag("SubrutineCall")
    namePath()
    argsList()
    closeTag("SubrutineCall")
  end
  
  def expressionOrVoid
    openTag("ExpressionOrVoid")
    if @currentToken.getType != TokenType::SEMICOLON
      expression()
    end
    closeTag("ExpressionOrVoid")
  end
  
  def expression
    openTag("Expression")
    operand()
    rightSide()
    closeTag("Expression")
  end
  
  def rightSide
    openTag("RightSide")
    if @currentToken.getType == TokenType::BINARY_OPERATOR || @currentToken.getValue == "-"
      printTokenAndReadNext()
      expression
    end
    closeTag("RightSide")
  end
  
  
  def operand
    openTag("Operand")
    type = @currentToken.getType
    if (type == TokenType::INTEGER_CONSTANT || type == TokenType::STRING_LITERAL || 
      type == TokenType::CONSTANT_VALUE_KEYWORD)
      printTokenAndReadNext()
    elsif type == TokenType::IDENTIFIER
      idOrFunctionCall()
    elsif @currentToken.getValue == "("
      printTokenAndReadNext()
      expression()
      if @currentToken.getValue == ")"
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \")\"")
      end
    elsif type == TokenType::UNARY_OPERATOR
      printTokenAndReadNext()
      operand()
    else
      printParseErrorMessage("Illigal operand")
    end
    closeTag("Operand")
  end
  
  def idOrFunctionCall
    openTag("IDOrFunctionCall")
    if @currentToken.getType == TokenType::IDENTIFIER
      printTokenAndReadNext()
      maybeFunction()
    end
    closeTag("IDOrFunctionCall")
  end
  
  
  def maybeFunction()
    openTag("MaybeFunction")
    if @currentToken.getValue == "."
      printTokenAndReadNext()
      namePath()
      argsList()
    elsif @currentToken.getValue == "("
      argsList()
    elsif @currentToken.getValue == "["
      atIndex()
    end
    closeTag("MaybeFunction")
  end
  
  
  def argsList
    openTag("ArgumentList")
    if @currentToken.getValue == "("
      printTokenAndReadNext()
      expressionListOrEmpty()
      if @currentToken.getValue == ")"
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \")\"")
      end
    else
      printParseErrorMessage("Expected \"(\"")
    end
    closeTag("ArgumentList")
  end
  
  def namePath
    openTag("NamePath")
    if @currentToken.getType == TokenType::IDENTIFIER
      printTokenAndReadNext()
      namePathCont()
    else
      printParseErrorMessage("Expected identifier")
    end
    closeTag("NamePath")
  end
  
  def namePathCont
    openTag("NamePathCont")
    if @currentToken.getValue == "."
      printTokenAndReadNext()
      namePath()
    end
    closeTag("NamePathCont")
  end
  
  def expressionListOrEmpty
    openTag("ExpressionListOrEmpty")
    if @currentToken.getValue != ")"
      expressionList()
    end
    closeTag("ExpressionListOrEmpty")
  end
  
  def expressionList
    openTag("ExpressionList")
    expression()
    expressionListCont()
    closeTag("ExpressionList")
  end
  
  def expressionListCont
    openTag("ExpressionListCont")
    if @currentToken.getType == TokenType::COMMA
      printTokenAndReadNext()
      expressionList()
    end
    closeTag("ExpressionListCont")
  end
  
end