require("utils")
Class = require("oo")

Node = Class()

--[[function Node:__init()
    self.__index = self
    setmetatable(o, self)
    self.__eq = function(other)
        return tostring(self) == tostring(other)
    end

end]]

local tokenLiteralAware = Class()
function tokenLiteralAware:getTokenLiteral()
    return self.token.literal
end

Statement = Node:extend(tokenLiteralAware)

Expression = Node:extend(tokenLiteralAware)

Identifier = Expression:extend()
Identifier.__tostring = function(v)
    return v.value
end

LetStatement = Statement:extend()
LetStatement.__tostring = function(v)
    return string.format("%s %s = %s", v:getTokenLiteral(), tostring(v.name), tostring(v.value))
end

Program = Node:extend()
Program.__tostring = function(v)
    return table.concat(Map(v.statements, function(statement)
        return tostring(statement)
    end), "")
end

function Program:getTokenLiteral()
    if #self.statements == 0 then
        return ""
    end
    return self.statements[1]:getTokenLiteral()
end

LiteralExpression = Expression:extend()

local function toStringLiteral(literal)
    return literal.token.literal
end

IntegerLiteral = LiteralExpression:extend()
IntegerLiteral.__tostring = toStringLiteral

BooleanLiteral = LiteralExpression:extend()
BooleanLiteral.__tostring = toStringLiteral

ReturnStatement = Statement:extend()
ReturnStatement.__tostring = function(v)
    return string.format("%s %s", tostring(v:getTokenLiteral()), tostring(v.returnValue))
end

ExpressionStatement = Statement:extend()
ExpressionStatement.__tostring = function(v)
    return tostring(self.expression)
end

PrefixExpression = Expression:extend()
PrefixExpression.__tostring = function(v)
    return string.format("%s%s", self.operator, tostring(self.right))
end