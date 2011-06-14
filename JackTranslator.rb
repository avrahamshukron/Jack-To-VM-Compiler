require "Token.rb"
require "JackTokenizer.rb"
require "Variable.rb"

class JackTranslator
  
  IF_TRUE_LABEL_TEMPLATE = "IF_TRUE_LABEL_"
  IF_FALSE_LABEL_TEMPLATE = "IF_FALSE_LABEL_Number_"
  IF_END_LABEL_TEMPLATE = "IF_END_LABEL_"
  
  WHILE_START_LABEL_TEMPLATE = "WHILE_START_LABEL_"
  WHILE_END_LABEL_TEMPLATE = "WHILE_END_LABEL_"
  def initialize(sourceCodeFilePath)
    @output = File.open(sourceCodeFilePath + ".vm","w")
    @currentToken = nil
    @tokenizer = JackTokenizer.new(sourceCodeFilePath)
    
    @ifLabelCount = 0
    @whileLabelCount = 0
    @className = nil
    @isConstructor = false
    @isMemberFunction = false
    @currentFunctionName = nil
    @classSymbolTable = Hash.new()
    @methodSymbolTable = Hash.new()
  end
  
  def printToFile(text)
    @output.write(text + "\n")
  end
  
  def start
    classDeclaration()
  end
  
  def resetCurrentMethodSymbolTable
    @methodSymbolTable = Hash.new
    Variable.localIndex = 0
    Variable.argumentIndex = 0
  end
  
  def printParseErrorMessage(message)
    puts message.to_s()
  end
  
  def readNextToken
    @currentToken = @tokenizer.getCurrentToken()
  end
  
  def printTokenAndReadNext
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
            printParseErrorMessage("Error: variable already exist")
          end
        when "static" ,"field"
          if ! @methodSymbolTable.include?(name)
            @classSymbolTable.store(name,Variable.new(name,type,kind))
          else
            printParseErrorMessage("Error: variable already exist")
          end
    end
  end
  
  def pushVariableNamed(varName)
    v = matchingSymbol(varName)
    printToFile("push " + v.kind + " " + v.index.to_s())
  end
  
  def popToVariableNamed(varName)
    v = matchingSymbol(varName)
    printToFile("pop " + v.kind + " " + v.index.to_s())
  end
  
  def classDeclaration
    readNextToken()
    if @currentToken.getValue == "class"
      printTokenAndReadNext()
      if @currentToken.getType == TokenType::IDENTIFIER
        # Saving the class name
        @className = @currentToken.getValue()
        printTokenAndReadNext()
        if @currentToken.getValue == "{"
          printTokenAndReadNext()
          classVarDecList()
          subrutineDecList()
          if @currentToken.getValue() == "}"
            printTokenAndReadNext()
          else
            printParseErrorMessage("Expected \"}\" at the end of class")
          end
        else
          printParseErrorMessage("Expected \"{\" at the beginning of class")
        end
      else
        printParseErrorMessage("Expected Identifier as class name")
      end
    else
      printParseErrorMessage("Expected \"class\" keyword")
    end
  end
  
  def classVarDec
      if @currentToken.getType == TokenType::CLASS_VAR_DESCRIPTOR
        kind = @currentToken.getValue()
        printTokenAndReadNext()
        type = type()
        idList(type , kind)
        if @currentToken.getType == TokenType::SEMICOLON
          printTokenAndReadNext()
        else
          printParseErrorMessage("Expected \";\"  at the end of class var declaration")
        end
      else
        printParseErrorMessage("Expected classVarDescriptor")
      end
  end
    
  def classVarDecList
    while @currentToken.getType == TokenType::CLASS_VAR_DESCRIPTOR
      classVarDec()
    end
  end
  
  def subrutineDecList()
    while (@currentToken.getType == TokenType::SUBRUTINE_DESCRIPTOR)
      subrutineDec()
    end
  end
  
  def idList(type , kind)
    if @currentToken.getType == TokenType::IDENTIFIER
      name = @currentToken.getValue()
      insertToSymbolTable(name,type,kind)
      printTokenAndReadNext()
      
      while @currentToken.getType == TokenType::COMMA
        printTokenAndReadNext()
        if @currentToken.getType == TokenType::IDENTIFIER
           name = @currentToken.getValue()
           insertToSymbolTable(name,type,kind)
           printTokenAndReadNext()
        end
      end
    else
      printParseErrorMessage("Expected identifier")
    end
  end
  
  def type
    toReturn = nil
    if (@currentToken.getType == TokenType::PRIMITIVE_TYPE || 
        @currentToken.getType == TokenType::IDENTIFIER)
      toReturn = @currentToken.getValue()
      printTokenAndReadNext()
    else
      printParseErrorMessage("Expected a type")
    end
    return toReturn
  end
  
  def subrutineDec
    # Reseting the symbol table of the current function
    resetCurrentMethodSymbolTable()
    if (@currentToken.getType == TokenType::SUBRUTINE_DESCRIPTOR)
      
      # Checking whether it is a member function or class function
      @isMemberFunction = (@currentToken.getValue == "method")   
      @isConstructor = (@currentToken.getValue == "constructor") 
      printTokenAndReadNext()
      returnType()
      if @currentToken.getType == TokenType::IDENTIFIER
        # Saving the current function name
        @currentFunctionName = @currentToken.getValue()
        printTokenAndReadNext()
        if @currentToken.getValue == "("
          printTokenAndReadNext()
          parameterList()
          if @currentToken.getValue == ")"
            printTokenAndReadNext()
            subrutineBody()
          else
            printParseErrorMessage("Expected \")\" at the end of parameter list")
          end
        else
          printParseErrorMessage("Expected \"(\" at the beggining of parameter list")
        end
      else
        printParseErrorMessage("Expected identifier as subrutine name")
      end
    else
      printParseErrorMessage("Expected subrutine descriptor")
    end
  end
  
  def returnType
    if @currentToken.getValue == "void"
      printTokenAndReadNext() 
    else
      type()
    end
  end
  
  def parameterList
    if (@currentToken.getType == TokenType::IDENTIFIER ||
       @currentToken.getType == TokenType::PRIMITIVE_TYPE)
      paramDec()
      while @currentToken.getType == TokenType::COMMA
        printTokenAndReadNext()
        paramDec()
      end
    end
  end
  
  def paramDec()
    # Get the parameter type
    type = type()
    if @currentToken.getType == TokenType::IDENTIFIER
      # Get The parameter name
      name = @currentToken.getValue()
      # inserting the parameter to the symbol table
      insertToSymbolTable(name,type,"argument")
      printTokenAndReadNext()
    else
      printParseErrorMessage("Expected parameter name")
    end
  end
  
  def numberOfVariablesOfKind(kind)
    case kind
    when "local"
      toReturn = Variable.localIndex
    when "argument"
      toReturn = Variable.argumentIndex
    when "field"
      toReturn = Variable.fieldIndex
    when "static"
      toReturn = Variable.staticIndex
    end
    return toReturn + 1
  end
  
  def translateSubrutinePrototype
    numberOfLocals = numberOfVariablesOfKind("local")
    printToFile("function " + @className + "." +@currentFunctionName + " " + numberOfLocals.to_s())
  end
  
  def translateConstruction
    numberOfFields = numberOfVariablesOfKind("field")
    printToFile("push constant " + numberOfFields.to_s())
    printToFile("call Memory.alloc 1")
    printToFile("pop pointer 0") 
  end
  
  def translateLoadingThisPointer
    printToFile("push argument 0")
    printToFile("pop pointer 0")
  end
  
  def subrutineBody
    if @currentToken.getValue == "{"
      printTokenAndReadNext()
      varDeclarationList()
      translateSubrutinePrototype()
      if @isConstructor
        translateConstruction()
      elsif @isMemberFunction
        translateLoadingThisPointer()
      end
      statements()
      if @currentToken.getValue == "}"
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \"}\" at the end of subrutine")
      end
    else
      printParseErrorMessage("Expected \"{\" at the beginning of subrutine")
    end
  end
  
  def varDeclarationList()
    while @currentToken.value == "var"
      varDeclaration()
    end
  end
  
  def varDeclaration()
    if @currentToken.getValue == "var"
      printTokenAndReadNext()
      type = type()
      toReturn = idList(type , "local")
      if @currentToken.getType == TokenType::SEMICOLON
        printTokenAndReadNext()
      else
        printParseErrorMessage("Expected \";\" at the end of var declaration")
      end
    else
      printParseErrorMessage("Expected \"var\"")
    end
  end
  
  def statements()
    while @currentToken.getType == TokenType::STATEMENTS
      singleStatement()
    end
  end

  def singleStatement
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
  end

  def atIndex(varName)
    if @currentToken.getValue == "["
      printTokenAndReadNext()
      expression()
      if @currentToken.getValue == "]"
        printTokenAndReadNext()
        pushVariableNamed(varName)
        printToFile("add")
      else
        printParseErrorMessage("Expected \"]\"")
      end
    end
  end
  
  def letStatement
    if @currentToken.getValue == "let"
      printTokenAndReadNext()
      if @currentToken.getType == TokenType::IDENTIFIER
        varName = @currentToken.value
        printTokenAndReadNext()
        atIndex(varName)
        if @currentToken.getValue == "="
          printTokenAndReadNext()
          expression()
          if @currentToken.getType == TokenType::SEMICOLON
            printTokenAndReadNext()
            pushVariableNamed(varName)
          else
            printParseErrorMessage("Expected \";\" at the end of let statement")
          end
        else
          printParseErrorMessage("Expected \"=\" at let statement")
        end
      else
        printParseErrorMessage("Expected identifier")
      end
    else
      printParseErrorMessage("Expected \"let\"")
    end
  end
  
  def doStatement
      if @currentToken.getValue == "do"
        printTokenAndReadNext()
        subrutineCall()
        if @currentToken.getType == TokenType::SEMICOLON
          printTokenAndReadNext()
        else
          printParseErrorMessage("Expected \";\" at the end of do statement")
        end
      else
        printParseErrorMessage("Expected \"do\"")
      end
  end
  
  def ifStatement
    # Incrementing label count
    currentLabelCount = @ifLabelCount.to_s()
    @ifLabelCount += 1
    #########################################
    if @currentToken.getValue == "if"
      printTokenAndReadNext()
      if @currentToken.getValue == "("
        printTokenAndReadNext()
        expression()
        if @currentToken.getValue == ")"
          printTokenAndReadNext()
          ### Compiling Jumps
          printToFile("if-goto " + IF_TRUE_LABEL_TEMPLATE + currentLabelCount)
          printToFile("goto " + IF_FALSE_LABEL_TEMPLATE + currentLabelCount)
          printToFile("label " + IF_TRUE_LABEL_TEMPLATE + currentLabelCount)
          if @currentToken.getValue == "{"
            printTokenAndReadNext()
            statements()
            # If i'm here the condition was true. jump to the end and skip the "else"
            printToFile("goto " + IF_END_LABEL_TEMPLATE + currentLabelCount)
            printToFile("label " + IF_FALSE_LABEL_TEMPLATE + currentLabelCount)
            if @currentToken.getValue == "}"
              printTokenAndReadNext()
              elseStatement()
            else
              printParseErrorMessage("Expected \"}\" at the end of if")
            end
          else
            printParseErrorMessage("Expected \"{\" after if")
          end
        else
          printParseErrorMessage("Expected \")\" after condition ")
        end
      else
        printParseErrorMessage("Expected \"(\" before condition")
      end
    else
      printParseErrorMessage("Expected \"if\"")
    end
    printToFile("label " + IF_END_LABEL_TEMPLATE + currentLabelCount)
  end
  
  def elseStatement
    if @currentToken.getValue == "else"
      printTokenAndReadNext()
      if @currentToken.getValue == "{"
        printTokenAndReadNext()
        statements()
        if @currentToken.getValue == "}"
          printTokenAndReadNext()
        else
          printParseErrorMessage("Expected \"}\" after else")
        end
      else
        printParseErrorMessage("Expected \"{\" before else")
      end
    else
      printParseErrorMessage("Expected \"else\"")
    end
  end
  
  def whileStatement
    #Incrementing the while label
    currentLabelIndex = @whileLabelCount
    @whileLabelCount += 1
    #####################################
    
    printToFile("label " + WHILE_START_LABEL_TEMPLATE + currentLabelIndex)
 
    if @currentToken.getValue == "while"
      printTokenAndReadNext()
      if @currentToken.getValue == "("
        printTokenAndReadNext()
        expression()
        
        printToFile("not")
        printToFile("if-goto " + WHILE_END_LABEL_TEMPLATE + currentLabelIndex)
        
        if @currentToken.getValue == ")"
          printTokenAndReadNext()
          if @currentToken.getValue == "{"
            printTokenAndReadNext()
            statements()
            if @currentToken.getValue == "}"
              printTokenAndReadNext()
              
              printToFile("goto " + WHILE_START_LABEL_TEMPLATE + currentLabelIndex)
              printToFile("label " + WHILE_END_LABEL_TEMPLATE + currentLabelIndex)
            else
              printParseErrorMessage("Expected \"}\" after while")
            end
          else
            printParseErrorMessage("Expected \"{\" before while")
          end
        else
          printParseErrorMessage("Expected \")\" after condition")
        end
      else
        printParseErrorMessage("Expected \"(\" before condition")
      end
    else
      printParseErrorMessage("Expected \"while\"")
    end
  end
  
  def returnStatement
    if @currentToken.getValue == "return"
      printTokenAndReadNext()
      expressionOrVoid()
      if @currentToken.getType == TokenType::SEMICOLON
        printTokenAndReadNext()
        printToFile("return")
      else
        printParseErrorMessage("Expected \";\" after return")
      end
    else
      printParseErrorMessage("Expected \"return\"")
    end
  end
  
  def subrutineCall
    namePath()
    argsList()
  end
  
  def expressionOrVoid
    if @currentToken.getType != TokenType::SEMICOLON
      expression()
    else
      printToFile("push constant 0")
    end
  end
  
  def expression
    operand()
    while (@currentToken.type == TokenType::BINARY_OPERATOR || 
                                    @currentToken.value == "-")
      op = @currentToken.value
      printTokenAndReadNext()
      operand()
      translateOperatorToFunctionCall(op)
    end
  end
  def translateOperatorToFunctionCall(op)
    if op == "+"
      printToFile("add")
    elsif op == "-"
      printToFile("sub")
    elsif op == "*"
      printToFile("call Math.multiply 2")
    elsif op == "/"
      printToFile("call Math.divide 2")
    elsif op == "&"
      printToFile("and")
    elsif op == '|'
      printToFile("or")
    elsif op == "<"
      printToFile("lt")
    elsif op == ">"
      printToFile("gt")
    elsif op == '='
      printToFile("eq")
    end
  end
  
  def translateStringLiteral(s)
    printToFile("push constant " + s.length)
    printToFile("call String.new 1")
    s.to_s().each_byte do |c|
      printToFile("push constant " + c)
      printToFile("call String.appendChar 2")
    end
  end
  
  def operand
    type = @currentToken.type
    value = @currentToken.value
    if type == TokenType::INTEGER_CONSTANT
      printToFile("push constant " + value.to_s())
      printTokenAndReadNext()
    elsif type == TokenType::STRING_LITERAL
      translateStringLiteral(value)
      printTokenAndReadNext()
    elsif type == TokenType::CONSTANT_VALUE_KEYWORD
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
      if value == "-"
        printToFile("neg")
      elsif value == "~"
        printToFile("not")
      end
    else
      printParseErrorMessage("Illigal operand")
    end
  end
  
  def idOrFunctionCall
    if @currentToken.getType == TokenType::IDENTIFIER
      printTokenAndReadNext()
      maybeFunction()
    end
  end
  
  
  def maybeFunction()
    if @currentToken.getValue == "."
      printTokenAndReadNext()
      namePath()
      argsList()
    elsif @currentToken.getValue == "("
      argsList()
    elsif @currentToken.getValue == "["
      atIndex()
    end
  end
  
  
  def argsList
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
  end
  
  def namePath
    if @currentToken.getType == TokenType::IDENTIFIER
      printTokenAndReadNext()
      namePathCont()
    else
      printParseErrorMessage("Expected identifier")
    end
  end
  
  def namePathCont
    if @currentToken.getValue == "."
      printTokenAndReadNext()
      namePath()
    end
  end
  
  def expressionListOrEmpty
    if @currentToken.getValue != ")"
      expressionList()
    end
  end
  
  def expressionList
    expression()
    expressionListCont()
  end
  
  def expressionListCont
    if @currentToken.getType == TokenType::COMMA
      printTokenAndReadNext()
      expressionList()
    end
  end
  
end