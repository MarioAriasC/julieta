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

local function parseInfixExpression(p, left)
    local token = p.curToken
    local operator = token.literal
    local precedence = p:curPrecedence()
    p:nextToken()
    local right = p:parseExpression(precedence)
    return InfixExpression { token = token, left = left, operator = operator, right = right }
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
        [LPAREN] = function(p)
            p:nextToken()
            local expression = p:parseExpression(LOWEST)
            if p:expectPeek(RPAREN) then
                return expression
            end
            return nil
        end,
        [LBRACKET] = function(p)
            local token = p.curToken
            return ArrayLiteral { token = token, elements = p:parseExpressionList(RBRACKET) }
        end,
        [IF] = function(p)
            local token = p.curToken
            if not p:expectPeek(LPAREN) then
                return nil
            end
            p:nextToken()
            local condition = p:parseExpression(LOWEST)
            if not p:expectPeek(RPAREN) then
                return nil
            end

            if not p:expectPeek(LBRACE) then
                return nil
            end

            local consequence = p:parseBlockStatement()
            local alternative
            if p:peekTokenIs(ELSE) then
                p:nextToken()
                if not p:expectPeek(LBRACE) then
                    return nil
                end
                alternative = p:parseBlockStatement()
            end
            return IfExpression { token = token, condition = condition, consequence = consequence, alternative = alternative }
        end,
        [FUNCTION] = function(p)
            local token = p.curToken
            if not p:expectPeek(LPAREN) then
                return nil
            end

            local parameters = p:parseFunctionParameters()
            if not p:expectPeek(LBRACE) then
                return nil
            end
            local body = p:parseBlockStatement()
            return FunctionLiteral { token = token, parameters = parameters, body = body }
        end,
        [STRING] = function(p)
            return StringLiteral { token = p.curToken, value = p.curToken.literal }
        end,
        [LBRACE] = function(p)
            local token = p.curToken
            local entries = {}
            while not p:peekTokenIs(RBRACE) do
                p:nextToken()
                local key = p:parseExpression(LOWEST)
                if not p:expectPeek(COLON) then
                    return nil
                end
                p:nextToken()
                local value = p:parseExpression(LOWEST)
                entries[key] = value
                --print("parseHashLiteral", "entries", #entries)
                if (not p:peekTokenIs(RBRACE)) and (not p:expectPeek(COMMA)) then
                    return nil
                end

            end
            if p:expectPeek(RBRACE) then
                return HashLiteral { token = token, entries = entries }
            end
            return nil
        end
    }
    self.infixParsers = {
        [PLUS] = parseInfixExpression,
        [MINUS] = parseInfixExpression,
        [SLASH] = parseInfixExpression,
        [ASTERISK] = parseInfixExpression,
        [EQ] = parseInfixExpression,
        [NOT_EQ] = parseInfixExpression,
        [LT] = parseInfixExpression,
        [GT] = parseInfixExpression,
        [LPAREN] = function(p, expression)
            local token = p.curToken
            local arguments = p:parseExpressionList(RPAREN)
            return CallExpression { token = token, expression = expression, arguments = arguments }
        end,
        [LBRACKET] = function(p, left)
            local token = p.curToken
            p:nextToken()
            local index = p:parseExpression(LOWEST)
            if p:expectPeek(RBRACKET) then
                return IndexExpression { token = token, left = left, index = index }
            end
            return nil
        end
    }
    self.precedences = {
        [EQ] = EQUALS,
        [NOT_EQ] = EQUALS,
        [LT] = LESS_GREATER,
        [GT] = LESS_GREATER,
        [PLUS] = SUM,
        [MINUS] = SUM,
        [SLASH] = PRODUCT,
        [ASTERISK] = PRODUCT,
        [LPAREN] = CALL,
        [LBRACKET] = INDEX,
    }
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
    while (not (self:peekTokenIs(SEMICOLON)) and (precedence < self:peekPrecedence())) do
        local infix = self.infixParsers[self.peekToken.tokenType]
        if infix == nil then
            return left
        end

        self:nextToken()
        left = infix(self, left)
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

function Parser:parseExpressionList(endTokenType)
    local arguments = {}
    if self:peekTokenIs(endTokenType) then
        self:nextToken()
        return arguments
    end

    self:nextToken()
    table.insert(arguments, self:parseExpression(LOWEST))

    while self:peekTokenIs(COMMA) do
        self:nextToken()
        self:nextToken()
        table.insert(arguments, self:parseExpression(LOWEST))
    end

    if self:expectPeek(endTokenType) then
        return arguments
    end
    return nil
end

function Parser:parseBlockStatement()
    local token = self.curToken
    local statements = {}
    self:nextToken()

    while (not self:curTokenIs(RBRACE)) and (not self:curTokenIs(EOF)) do
        local statement = self:parseStatement()
        if statement ~= nil then
            table.insert(statements, statement)
        end
        self:nextToken()
    end
    return BlockStatement { token = token, statements = statements }
end

function Parser:parseFunctionParameters()
    local parameters = {}
    if self:peekTokenIs(RPAREN) then
        self:nextToken()
        return parameters
    end

    self:nextToken()
    local token = self.curToken

    table.insert(parameters, Identifier { token = token, value = token.literal })

    while self:peekTokenIs(COMMA) do
        self:nextToken()
        self:nextToken()
        local innerToken = self.curToken
        table.insert(parameters, Identifier { token = innerToken, value = innerToken.literal })
    end

    if not self:expectPeek(RPAREN) then
        return nil
    end

    return parameters
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

function Parser:curPrecedence()
    return self:findPrecedence(self.curToken.tokenType)
end

function Parser:peekError(tokenType)
    table.insert(self.errors, string.format("Expected next token to be %s, got %s instead", tokenType, self.peekToken.tokenType))
end