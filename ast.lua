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
    return string.format("%s %s = %s", v:getTokenLiteral(), v.name, v.value)
end

Program = Node:extend()
Program.__tostring = function(v)
    return table.concat(Map(v.statements, tostring), "")
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
    return string.format("%s %s", v:getTokenLiteral(), v.returnValue)
end

ExpressionStatement = Statement:extend()
ExpressionStatement.__tostring = function(v)
    return tostring(v.expression)
end

PrefixExpression = Expression:extend()
PrefixExpression.__tostring = function(v)
    return string.format("(%s%s)", v.operator, v.right)
end

InfixExpression = Expression:extend()
InfixExpression.__tostring = function(v)
    return string.format("(%s %s %s)", v.left, v.operator, v.right)
end

CallExpression = Expression:extend()
CallExpression.__tostring = function(v)
    return string.format("%s(%s)", v.expression, table.concat(Map(v.arguments, tostring), ", "))
end

ArrayLiteral = Expression:extend()
ArrayLiteral.__tostring = function(v)
    return string.format("[%s]", table.concat(Map(v.elements, tostring), ", "))
end

IndexExpression = Expression:extend()
IndexExpression.__tostring = function(v)
    return string.format("(%s[%s])", v.left, v.index)
end

BlockStatement = Statement:extend()
BlockStatement.__tostring = function(v)
    if v.statements == nil then
        return ""
    end
    return table.concat(Map(v.statements, tostring), "")
end

IfExpression = Expression:extend()
IfExpression.__tostring = function(v)
    local alt
    if v.alternative ~= nil then
        alt = string.format("else %s", v.alternative)
    else
        alt = ""
    end
    return string.format("%s %s %s", v.condition, v.consequence, alt)
end

FunctionLiteral = Expression:extend()
FunctionLiteral.__tostring = function(v)
    return string.format("%s(%s)", v.tokenLiteral, table.concat(Map(v.parameters, tostring), ", "), v.body)
end

StringLiteral = Expression:extend()
StringLiteral.__tostring = function(v)
    return v.value
end

HashLiteral = Expression:extend()
HashLiteral.__tostring = function(v)
    return string.format("{%s}", table.concat(Map(Keys(v.entries), function(key)
        return string.format("%s:%s", key, v.entries[key])
    end), ", "))
end

