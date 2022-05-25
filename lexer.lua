require("tokens")
require("utils")
require("oo")

local function isIdentifier(char)
    if string.match(char, "%a") or char == "_" then
        return true
    end
    return false
end

local function isDigit(char)
    if tonumber(char) ~= nil then
        return true
    end
    return false
end

ZERO = ""

Lexer = Class()

function Lexer:__init()
    self.position = 1
    self.readPosition = 1
    self.ch = ZERO
    self:readChar()
end

function Lexer:readChar()
    self.ch = self:peakChar()
    self.position = self.readPosition
    self.readPosition = (self.readPosition + 1)
end

function Lexer:peakChar()

    if self.readPosition > #self.input then
        return ZERO
    else
        return string.sub(self.input, self.readPosition, self.readPosition)
    end
end

function Lexer:nextToken()
    local function endsWithEqual(oneChar, twoChar, duplicateChar)
        if self:peakChar() ~= "=" then
            return self:token(oneChar)
        end
        local currentChar = self.ch
        self:readChar()
        return Token { tokenType = twoChar, literal = Ternary(duplicateChar, string.format("%s%s", currentChar, currentChar), string.format("%s%s", currentChar, self.ch)) }
    end

    self:skipWhitespace()

    local switch = {
        ["="] = function()
            return endsWithEqual(ASSIGN, EQ, true)
        end,
        [";"] = function()
            return self:token(SEMICOLON)
        end,
        [":"] = function()
            return self:token(COLON)
        end,
        [","] = function()
            return self:token(COMMA)
        end,
        ["("] = function()
            return self:token(LPAREN)
        end,
        [")"] = function()
            return self:token(RPAREN)
        end,
        ["{"] = function()
            return self:token(LBRACE)
        end,
        ["}"] = function()
            return self:token(RBRACE)
        end,
        ["["] = function()
            return self:token(LBRACKET)
        end,
        ["]"] = function()
            return self:token(RBRACKET)
        end,
        ["+"] = function()
            return self:token(PLUS)
        end,
        ["-"] = function()
            return self:token(MINUS)
        end,
        ["*"] = function()
            return self:token(ASTERISK)
        end,
        ["/"] = function()
            return self:token(SLASH)
        end,
        ["<"] = function()
            return self:token(LT)
        end,
        [">"] = function()
            return self:token(GT)
        end,
        ["!"] = function()
            return endsWithEqual(BANG, NOT_EQ, false)
        end,
        ['"'] = function()
            return Token { tokenType = STRING, literal = self:readString() }
        end,
        [ZERO] = function()
            return Token { tokenType = EOF, literal = "" }
        end

    }
    local f = switch[self.ch]
    if f ~= nil then
        local r = f()
        self:readChar()
        return r
    end
    if isIdentifier(self.ch) then
        local identifier = self:readIdentifier()
        return Token { tokenType = LookupIdent(identifier), literal = identifier }
    end
    if isDigit(self.ch) then
        return Token { tokenType = INT, literal = self:readNumber() }
    end
    return Token { tokenType = ILLEGAL, self.ch }
end

function Lexer:skipWhitespace()
    local function isWhiteSpace(char)
        if char == " " or char == "\n" or char == "\t" or char == "\r" then
            return true
        end
        return false
    end

    while isWhiteSpace(self.ch) do
        self:readChar()
    end
end

function Lexer:readIdentifier()
    return self:readValue(isIdentifier)
end

function Lexer:readNumber()
    return self:readValue(isDigit)
end

function Lexer:readValue(predicate)
    local currentPosition = self.position
    while predicate(self.ch) do
        self:readChar()
    end
    return string.sub(self.input, currentPosition, (self.position - 1))
end

function Lexer:token(tokenType)
    return Token { tokenType = tokenType, literal = self.ch }
end

function Lexer:readString()
    local start = self.position + 1
    while true do
        self:readChar()
        if self.ch == '"' or self.ch == ZERO then
            break
        end
    end
    return string.sub(self.input, start, (self.position - 1))
end
