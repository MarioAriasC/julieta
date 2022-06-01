require("objects")

Class = require("oo")
Environment = Class()
function Environment:__init()
    if self.store == nil then
        self.store = {}
    end
end
--[[Environment.__newindex = function(env, key, value)
    print("Environment", "newindex", env, key, value)
    env.store[key] = value
end]]

function Environment:set(key, value)
    self.store[key] = value
end

function Environment:get(key)
    local obj = self.store[key]
    if obj ~= nil then
        return obj
    end
    if self.outer ~= nil then
        return self.outer:get(key)
    end
    return obj
end

local function evalProgram(statements, env)
    local result
    for i = 1, #statements do
        result = Eval(statements[i], env)
        if result:is(MReturnValue) then
            return result.value
        end
        if result:is(MError) then
            return result
        end
    end
    return result
end

local function ifNotError(obj, body)
    if obj:is(MError) then
        return obj
    end
    return body(obj)
end

local function evalMinusPrefixOperatorExpression(right)
    if right == nil then
        return nil
    end

    if right:is(MInteger) then
        return -right
    end
    return MError { message = string.format("unknown operator: -%s", right.className) }
end

local function evalBangOperatorExpression(right)
    if right == M_TRUE then
        return M_FALSE
    end
    if right == M_FALSE then
        return M_TRUE
    end
    if right == M_NULL then
        return M_TRUE
    end
    return M_FALSE
end

local function evalPrefixExpression(operator, right)
    if operator == "!" then
        return evalBangOperatorExpression(right)
    end
    if operator == "-" then
        return evalMinusPrefixOperatorExpression(right)
    end
    return MError { message = string.format("Unknown operator : %s%s", operator, right.className) }
end

local function toMBoolean(value)
    return MBoolean.fromBoolean(value)
end

local function evalIntegerInfixExpression(operator, left, right)
    if operator == "+" then
        return left + right
    end
    if operator == "-" then
        return left - right
    end
    if operator == "*" then
        return left * right
    end
    if operator == "/" then
        return left / right
    end
    if operator == "<" then
        return toMBoolean(left < right)
    end
    if operator == ">" then
        return toMBoolean(left > right)
    end
    if operator == "==" then
        return toMBoolean(left == right)
    end
    if operator == "!=" then
        return toMBoolean(left ~= right)
    end
    return MError { message = string.format("unknown operator: %s %s %s", "MInteger", operator, "MInteger") }
end

local function evalStringInfixExpression(operator, left, right)
    if operator == "+" then
        return left + right
    end
    return MError { message = string.format("unknown operator: %s %s %s", left.className, operator, right.className) }
end

local function evalInfixExpression(operator, left, right)
    if left:is(MInteger) and right:is(MInteger) then
        return evalIntegerInfixExpression(operator, left, right)
    end
    if operator == "==" then
        return toMBoolean(left == right)
    end
    if operator == "!=" then
        return toMBoolean(left ~= right)
    end
    if left.className ~= right.className then
        return MError { message = string.format("type mismatch: %s %s %s", left.className, operator, right.className) }
    end
    if left:is(MString) and right:is(MString) then
        return evalStringInfixExpression(operator, left, right)
    end
    return MError { message = string.format("unknown operator: %s %s %s", left.className, operator, right.className) }
end

local function isTruthy(obj)
    if obj:is(MBoolean) then
        return obj.value
    end
    if obj == M_NULL then
        return false
    end
    return true
end

local function evalIfExpression(node, env)
    return ifNotError(Eval(node.condition, env), function(condition)
        if isTruthy(condition) then
            return Eval(node.consequence, env)
        end
        if node.alternative ~= nil then
            return Eval(node.alternative, env)
        end
        return M_NULL
    end)
end

local function evalBlockStatement(node, env)
    local result
    for i = 1, #node.statements do
        result = Eval(node.statements[i], env)
        if result:is(MReturnValue) or result:is(MError) then
            return result
        end
    end
    return result
end

local function evalIdentifier(identifier, env)
    local value = env:get(identifier)
    if value ~= nil then
        return value
    end
    local builtin = BUILTINS[identifier]
    if builtin ~= nil then
        return builtin
    end
    return MError { message = string.format("identifier not found: %s", identifier) }
end

local function isError(obj)
    return obj:is(MError)
end

local function evalExpressions(arguments, env)
    local args = {}
    for i = 1, #arguments do
        local evaluated = Eval(arguments[i], env)
        if isError(evaluated) then
            return { evaluated }
        end
        table.insert(args, evaluated)
    end
    return args
end

local function extendFunctionEnv(fn, args)
    local env = Environment { outer = fn.env }
    ForEachIndexed(fn.parameters, function(i, identifier)
        env:set(identifier.value, args[i])
    end)
    return env
end

local function unwrapReturnValue(evaluated)
    if evaluated:is(MReturnValue) then
        return evaluated.value
    end
    return evaluated
end

local function applyFunction(fn, args)
    if fn:is(MFunction) then
        local extendEnv = extendFunctionEnv(fn, args)
        local evaluated = Eval(fn.body, extendEnv)
        return unwrapReturnValue(evaluated)
    end
    if fn:is(MBuiltinFunction) then
        local result = fn.fn(args)
        if result == nil then
            return M_NULL
        end
        return result
    end
    return MError { message = string.format("not a function: %s", fn.className) }
end

local function evalHashIndexExpression(entries, index)

    if index:is(MValue) then
        local entry = entries[tostring(index:hashKey())]
        if entry == nil then
            return M_NULL
        end
        return entry.value
    end
    return MError { message = string.format("unusable as a hash key: %s", index.className) }
end

local function evalArrayIndexExpression(elements, index)
    if (index < 0) or (index > Len(elements) - 1) then
        return M_NULL
    end
    return elements[index + 1]
end

local function evalIndexExpression(left, index)
    if left:is(MArray) and index:is(MInteger) then
        return evalArrayIndexExpression(left.elements, index.value)
    end
    if left:is(MHash) then
        return evalHashIndexExpression(left.entries, index)
    end
    return MError { message = string.format("index operator not supported: %s", left.className) }
end

local function evalHashLiteral(hashPairs, env)
    local p = {}
    for keyNode, valueNode in pairs(hashPairs) do
        local key = Eval(keyNode, env)
        if isError(key) then
            return key
        end
        if key:is(MValue) then
            local value = Eval(valueNode, env)
            if isError(value) then
                return value
            end
            p[tostring(key:hashKey())] = HashPair { key = key, value = value }
        else
            return MError { message = string.format("unusable as hash key: %s", key.className) }
        end
    end
    return MHash { entries = p }
end

function Eval(node, env)
    --print("eval", node)
    if node:is(Program) then
        return evalProgram(node.statements, env)
    end
    if node:is(Identifier) then
        return evalIdentifier(node.value, env)
    end
    if node:is(IntegerLiteral) then
        return MInteger { value = node.value }
    end
    if node:is(InfixExpression) then
        return ifNotError(Eval(node.left, env), function(left)
            return ifNotError(Eval(node.right, env), function(right)
                return evalInfixExpression(node.operator, left, right)
            end)
        end)
    end
    if node:is(BlockStatement) then
        return evalBlockStatement(node, env)
    end
    if node:is(ExpressionStatement) then
        return Eval(node.expression, env)
    end
    if node:is(IfExpression) then
        return evalIfExpression(node, env)
    end
    if node:is(CallExpression) then
        return ifNotError(Eval(node.expression, env), function(f)
            local args = evalExpressions(node.arguments, env)
            if #args == 1 and isError(args[1]) then
                return args[1]
            end
            return applyFunction(f, args)
        end)
    end
    if node:is(ReturnStatement) then
        return ifNotError(Eval(node.returnValue, env), function(value)
            return MReturnValue { value = value }
        end)
    end
    if node:is(PrefixExpression) then
        return ifNotError(Eval(node.right, env), function(right)
            return evalPrefixExpression(node.operator, right)
        end)
    end
    if node:is(BooleanLiteral) then
        return toMBoolean(node.value)
    end
    if node:is(LetStatement) then
        return ifNotError(Eval(node.value, env), function(value)
            --env[node.name.value] = value
            env:set(node.name.value, value)
            return value
        end)
    end
    if node:is(FunctionLiteral) then
        return MFunction { parameters = node.parameters, body = node.body, env = env }
    end
    if node:is(StringLiteral) then
        return MString { value = node.value }
    end
    if node:is(IndexExpression) then
        local left = Eval(node.left, env)
        if isError(left) then
            return left
        end

        local index = Eval(node.index, env)
        if isError(index) then
            return index
        end
        return evalIndexExpression(left, index)
    end
    if node:is(HashLiteral) then
        return evalHashLiteral(node.entries, env)
    end
    if node:is(ArrayLiteral) then
        local elements = evalExpressions(node.elements, env)
        if #elements == 1 and isError(elements[1]) then
            return elements[1]
        end
        return MArray { elements = elements }
    end
    print(string.format("%s => %s", node, node.className))
    return nil
end

