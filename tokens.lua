TokenType = {}

function TokenType:new(o)
  self.__index = self
  setmetatable(o, self)
  self.__tostring = function(v)
      return string.format("TokenType(%s)", v:getText())
  end
  return o
end

function TokenType:getValue()
  return self.value
end

function TokenType:getText()
  return self.text
end

function TokenType:getClassName()
  return "TokenType"
end

function TokenType:equals(other)
  if other.getClassName() == "TokenType" then
    return self.getValue() == other.getValue()
  else
    error("Comparing TokenType with a value from another class:" + other.getClassName())
  end
end

ILLEGAL = TokenType:new { value = 0, text = "ILLEGAL" }
EOF = TokenType:new { value = 1, text = "EOF" }
ASSIGN = TokenType:new { value = 2, text = "=" }
EQ = TokenType:new { value = 3, text = "==" }
NOT_EQ = TokenType:new { value = 4, text = "!=" }
IDENT = TokenType:new { value = 5, text = "IDENT" }
INT = TokenType:new { value = 6, text = "INT" }
PLUS = TokenType:new { value = 7, text = "+" }
COMMA = TokenType:new { value = 8, text = "," }
SEMICOLON = TokenType:new { value = 9, text = ";" }
COLON = TokenType:new { value = 10, text = ":" }
MINUS = TokenType:new { value = 11, text = "-" }
BANG = TokenType:new { value = 12, text = "!" }
SLASH = TokenType:new { value = 13, text = "/" }
ASTERISK = TokenType:new { value = 14, text = "*" }
LT = TokenType:new { value = 15, text = "<" }
GT = TokenType:new { value = 16, text = ">" }
LPAREN = TokenType:new { value = 17, text = "(" }
RPAREN = TokenType:new { value = 18, text = ")" }
LBRACE = TokenType:new { value = 19, text = "{" }
RBRACE = TokenType:new { value = 20, text = "}" }
LBRACKET = TokenType:new { value = 21, text = "[" }
RBRACKET = TokenType:new { value = 22, text = "]" }
FUNCTION = TokenType:new { value = 23, text = "FUNCTION" }
LET = TokenType:new { value = 24, text = "LET" }
TRUE = TokenType:new { value = 25, text = "TRUE" }
FALSE = TokenType:new { value = 26, text = "FALSE" }
IF = TokenType:new { value = 27, text = "IF" }
ELSE = TokenType:new { value = 28, text = "ELSE" }
RETURN = TokenType:new { value = 29, text = "RETURN" }
STRING = TokenType:new { value = 30, text = "STRING" }

local keywords = {
  ["fn"] = FUNCTION,
  ["let"] = LET,
  ["true"] = TRUE,
  ["false"] = FALSE,
  ["if"] = IF,
  ["else"] = ELSE,
  ["return"] = RETURN
}

function LookupIdent(name)
  local reserved = keywords[name]
  if reserved == nil then
    return IDENT
  else
    return reserved
  end
end

Token = {}

function Token:new(o)
  self.__index = self
  setmetatable(o, self)
  self.__tostring = function(v)
    return string.format("Token(tokenType:%s, literal:'%s')", tostring(v:getTokenType()), v:getLiteral())
  end
  return o
end

function Token:getTokenType()
  return self.tokenType
end

function Token:getLiteral()
  return self.literal
end

