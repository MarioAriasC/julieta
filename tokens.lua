Class = require("oo")
TokenType = Class()
TokenType.__tostring = function(v)
    return string.format("TokenType(%s)", v.text)
end

--[[TokenType = {}

function TokenType:getClassName()
    return "TokenType"
end

function TokenType:equals(other)
    if other.getClassName() == "TokenType" then
        return self.getValue() == other.getValue()
    else
        error("Comparing TokenType with a value from another class:" + other.getClassName())
    end
end]]

ILLEGAL = TokenType { value = 0, text = "ILLEGAL" }
EOF = TokenType { value = 1, text = "EOF" }
ASSIGN = TokenType { value = 2, text = "=" }
EQ = TokenType { value = 3, text = "==" }
NOT_EQ = TokenType { value = 4, text = "!=" }
IDENT = TokenType { value = 5, text = "IDENT" }
INT = TokenType { value = 6, text = "INT" }
PLUS = TokenType { value = 7, text = "+" }
COMMA = TokenType { value = 8, text = "," }
SEMICOLON = TokenType { value = 9, text = ";" }
COLON = TokenType { value = 10, text = ":" }
MINUS = TokenType { value = 11, text = "-" }
BANG = TokenType { value = 12, text = "!" }
SLASH = TokenType { value = 13, text = "/" }
ASTERISK = TokenType { value = 14, text = "*" }
LT = TokenType { value = 15, text = "<" }
GT = TokenType { value = 16, text = ">" }
LPAREN = TokenType { value = 17, text = "(" }
RPAREN = TokenType { value = 18, text = ")" }
LBRACE = TokenType { value = 19, text = "{" }
RBRACE = TokenType { value = 20, text = "}" }
LBRACKET = TokenType { value = 21, text = "[" }
RBRACKET = TokenType { value = 22, text = "]" }
FUNCTION = TokenType { value = 23, text = "FUNCTION" }
LET = TokenType { value = 24, text = "LET" }
TRUE = TokenType { value = 25, text = "TRUE" }
FALSE = TokenType { value = 26, text = "FALSE" }
IF = TokenType { value = 27, text = "IF" }
ELSE = TokenType { value = 28, text = "ELSE" }
RETURN = TokenType { value = 29, text = "RETURN" }
STRING = TokenType { value = 30, text = "STRING" }

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

Token = Class()
Token.__tostring = function(v)
    return string.format("Token(tokenType:%s, literal:'%s')", tostring(v.tokenType), v.literal)
end

