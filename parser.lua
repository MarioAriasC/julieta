require("tokens")
require("ast")
Class = require("oo")
local LOWEST = 1
local EQUALS = 2
local LESS_GREATER = 3
local SUM = 4
local PRODUCT = 5
local PREFIX = 6
local CALL = 7
local INDEX = 8

Parser = Class()

local function parseBooleanLiteral(p)
    return BooleanLiteral { token = p.curToken, value = p:curTokenIs(TRUE) }
end

local function parsePrefixExpression(p)
    local token = p.curToken
    local operator = token.literal
    p:nextToken()

    local right = p:parseExpression(PREFIX)
    return PrefixExpression { token = token, operator = operator, right = right }
end

function Parser:__init()
    self.curToken = nil
    self.peekToken = nil
    self:nextToken()
    self:nextToken()
    self.errors = {}
    self.prefixParsers = {
        [INT] = function(p)
            local token = p.curToken
            local value = tonumber(token.literal)
            if value ~= nil then
                return IntegerLiteral { token = token, value = value }
            end
            table.insert(p.errors, string.format("count not parse %s as integer", token.literal))
            return nil
        end,
        [TRUE] = parseBooleanLiteral,
        [FALSE] = parseBooleanLiteral,
        [IDENT] = function(p)
            return Identifier { token = p.curToken, value = p.curToken.literal }
        end,
        [BANG] = parsePrefixExpression,
        [MINUS] = parsePrefixExpression,

    }
    self.precedences = {
        EQ = EQUALS,
        NOT_EQ = EQUALS,
        LT = LESS_GREATER,
        GT = LESS_GREATER,
        PLUS = SUM,
        MINUS = SUM,
        SLASH = PRODUCT,
        ASTERISK = PRODUCT,
        LPAREN = CALL,
        LBRACKET = INDEX,
    }
    return o
end

function Parser:parseProgram()
    local statements = {}
    while self.curToken.tokenType ~= EOF do
        local statement = self:parseStatement()
        if statement ~= nil then
            table.insert(statements, statement)
        end
        self:nextToken()
    end
    return Program { statements = statements }
end

function Parser:getErrors()
    return self.errors
end

function Parser:nextToken()
    self.curToken = self.peekToken
    self.peekToken = self.lexer:nextToken()
end

function Parser:parseStatement()
    local switch = {
        [LET] = function()
            return self:parseLetStatement()
        end,
        [RETURN] = function()
            return self:parseReturnStatement()
        end
    }
    local f = switch[self.curToken.tokenType]
    if f ~= nil then
        return f()
    end
    return self:parseExpressionStatement()
end

function Parser:parseLetStatement()
    local token = self.curToken
    if not self:expectPeek(IDENT) then
        return nil
    end

    local name = Identifier { token = self.curToken, value = self.curToken.literal }

    if not self:expectPeek(ASSIGN) then
        return nil
    end

    self:nextToken()

    local value = self:parseExpression(LOWEST)

    if self:peekTokenIs(SEMICOLON) then
        self:nextToken()
    end
    return LetStatement { token = token, name = name, value = value }
end

function Parser:parseExpression(precedence)
    local prefix = self.prefixParsers[self.curToken.tokenType]
    if prefix == nil then
        self:prefixParserError(self.curToken.tokenType)
        return nil
    end

    local left = prefix(self)

    while not self:peekTokenIs(SEMICOLON) and (precedence < self:peekPrecedence()) do
        local infix = self.infixParsers[self.peekToken.tokenType]
        if infix == nil then
            return left
        end

        self:nextToken()
        left = infix(left)
    end
    return left

end

function Parser:parseIntegerLiteral()

    local token = self.curToken

    local value = tonumber(token.literal)
    if value ~= nil then
        return IntegerLiteral { token = token, value = value }
    end
    table.insert(self.errors, string.format("count not parse %s as integer", token.literal))
    return nil
end

function Parser:parseReturnStatement()
    local token = self.curToken
    self:nextToken()
    local returnValue = self:parseExpression(LOWEST)
    while self:peekTokenIs(SEMICOLON) do
        self:nextToken()
    end
    return ReturnStatement { token = token, returnValue = returnValue }
end

function Parser:parseExpressionStatement()
    local token = self.curToken
    local expression = self:parseExpression(LOWEST)
    if self:peekTokenIs(SEMICOLON) then
        self:nextToken()
    end
    return ExpressionStatement { token = token, expression = expression }
end

function Parser:expectPeek(tokenType)
    if self:peekTokenIs(tokenType) then
        self:nextToken()
        return true
    end

    self:peekError(tokenType)
    return false
end

function Parser:peekTokenIs(tokenType)
    return self.peekToken.tokenType == tokenType
end

function Parser:prefixParserError(tokenType)
    table.insert(self.errors, string.format("no prefix parser for %s function", tokenType))
end

function Parser:peekPrecedence()
    return self:findPrecedence(self.peekToken.tokenType)
end

function Parser:findPrecedence(tokenType)
    local precedence = self.precedences[tokenType]
    if precedence ~= nil then
        return precedence
    end
    return LOWEST
end

function Parser:curTokenIs(tokenType)
    return self.curToken.tokenType == tokenType
end