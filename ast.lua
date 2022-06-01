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
Statement.className = "Statement"

Expression = Node:extend(tokenLiteralAware)
Expression.className = "Expression"

Identifier = Expression:extend()
Identifier.className = "Identifier"
Identifier.__tostring = function(v)
    return v.value
end

LetStatement = Statement:extend()
LetStatement.className = "LetStatement"
LetStatement.__tostring = function(v)
    return string.format("%s %s = %s", v:getTokenLiteral(), v.name, v.value)
end

Program = Node:extend()
Program.className = "Program"
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
LiteralExpression.className = "LiteralExpression"

local function toStringLiteral(literal)
    return literal.token.literal
end

IntegerLiteral = LiteralExpression:extend()
IntegerLiteral.className = "IntegerLiteral"
IntegerLiteral.__tostring = toStringLiteral

BooleanLiteral = LiteralExpression:extend()
BooleanLiteral.className = "BooleanLiteral"
BooleanLiteral.__tostring = toStringLiteral

ReturnStatement = Statement:extend()
ReturnStatement.className = "ReturnStatement"
ReturnStatement.__tostring = function(v)
    return string.format("%s %s", v:getTokenLiteral(), v.returnValue)
end

ExpressionStatement = Statement:extend()
ExpressionStatement.className = "ExpressionStatement"
ExpressionStatement.__tostring = function(v)
    return tostring(v.expression)
end

PrefixExpression = Expression:extend()
PrefixExpression.className = "PrefixExpression"
PrefixExpression.__tostring = function(v)
    return string.format("(%s%s)", v.operator, v.right)
end

InfixExpression = Expression:extend()
InfixExpression.className = "InfixExpression"
InfixExpression.__tostring = function(v)
    return string.format("(%s %s %s)", v.left, v.operator, v.right)
end

CallExpression = Expression:extend()
CallExpression.className = "CallExpression"
CallExpression.__tostring = function(v)
    return string.format("%s(%s)", v.expression, table.concat(Map(v.arguments, tostring), ", "))
end

ArrayLiteral = Expression:extend()
ArrayLiteral.className = "ArrayLiteral"
ArrayLiteral.__tostring = function(v)
    return string.format("[%s]", table.concat(Map(v.elements, tostring), ", "))
end

IndexExpression = Expression:extend()
IndexExpression.className = "IndexExpression"
IndexExpression.__tostring = function(v)
    return string.format("(%s[%s])", v.left, v.index)
end

BlockStatement = Statement:extend()
BlockStatement.className = "BlockStatement"
BlockStatement.__tostring = function(v)
    if v.statements == nil then
        return ""
    end
    return table.concat(Map(v.statements, tostring), "")
end

IfExpression = Expression:extend()
IfExpression.className = "IfExpression"
IfExpression.__tostring = function(v)
    local alt
    if v.alternative ~= nil then
        alt = string.format("else %s", v.alternative)
    else
        alt = ""
    end
    return string.format("if(%s) %s %s", v.condition, v.consequence, alt)
end

FunctionLiteral = Expression:extend()
FunctionLiteral.className = "FunctionLiteral"
FunctionLiteral.__tostring = function(v)
    return string.format("%s(%s)", v.tokenLiteral, table.concat(Map(v.parameters, tostring), ", "), v.body)
end

StringLiteral = Expression:extend()
StringLiteral.className = "StringLiteral"
StringLiteral.__tostring = function(v)
    return v.value
end

HashLiteral = Expression:extend()
HashLiteral.className = "HashLiteral"
HashLiteral.__tostring = function(v)
    return string.format("{%s}", table.concat(Map(Keys(v.entries), function(key)
        return string.format("%s:%s", key, v.entries[key])
    end), ", "))
end

