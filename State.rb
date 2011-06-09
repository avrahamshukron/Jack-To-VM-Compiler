#########################################################
##
##  All the states of the Lexical analizer automaton
##
#########################################################
class State
  START_STATE = 0
  ZERO_STATE = 1
  NUM_STATE = 2
  STRING_STATE = 3
  KEYWORD_APP_STATE = 4
  ID_STATE = 5
  SLASH_STATE = 6
  COMMENT_SINGLE_STATE = 7
  COMMENT_LONG_STATE = 8
  COMMENT_LONG_EXIT_APP_STATE = 9
  ERROR_STATE = 10
end