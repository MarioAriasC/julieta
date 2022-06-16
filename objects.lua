Class = require("oo")
HashType = Class()
HashType.__tostring = function(v)
    return v.name
end

HashType.INTEGER = HashType { name = "INTEGER" }
HashType.BOOLEAN = HashType { name = "BOOLEAN" }
HashType.STRING = HashType { name = "STRING" }

HashKey = Class()
HashKey.__tostring = function(v)
    return string.format("{hashType:%s => value:%s}", v.hashType, v.value)
end
--[[
HashKey.__eq = function(left, right)
    if left.hashType == right.hashType then
        return left.value == right.value
    end
    return false
end
]]

HashPair = Class()
HashPair.__tostring = function(v)
    return string.format("{key:%s => value:%s}", v.key, v.value)
end

Hashable = Class()
function Hashable:hashKey()
    return HashKey { hashType = self.hashType, value = self.value }
end

MObject = Class()
MObject.className = "MObject"

MValue = MObject:extend()
local toStringValue = function(v)
    return tostring(v.value)
end

MInteger = MValue:extend(Hashable)
MInteger.hashType = HashType.INTEGER
MInteger.__tostring = toStringValue
MInteger.className = "MInteger"

MInteger.__unm = function(v)
    return MInteger { value = -(v.value) }
end

MInteger.__add = function(left, right)
    return MInteger { value = left.value + right.value }
end

MInteger.__sub = function(left, right)
    return MInteger { value = left.value - right.value }
end

MInteger.__mul = function(left, right)
    return MInteger { value = left.value * right.value }
end

MInteger.__div = function(left, right)
    return MInteger { value = left.value / right.value }
end

MInteger.__lt = function(left, right)
    return left.value < right.value
end

MInteger.__eq = function(left, right)
    return left.value == right.value
end

MBoolean = MValue:extend(Hashable)
MBoolean.hashType = HashType.BOOLEAN
MBoolean.__tostring = toStringValue
MBoolean.className = "MBoolean"

M_TRUE = MBoolean { value = true }
M_FALSE = MBoolean { value = false }

MBoolean.fromBoolean = function(v)
    if v then
        return M_TRUE
    end
    return M_FALSE
end

MNull = MObject:extend()
MNull.className = "MNull"
MNull.__tostring = function(v)
    return "null"
end
M_NULL = MNull {}

MReturnValue = MObject:extend()
MReturnValue.className = "MReturnValue"
MReturnValue.__tostring = function(v)
    return tostring(v.value)
end

MFunction = MObject:extend()
MFunction.className = "MFunction"
MFunction.__tostring = function(v)
    local parameters
    if v.parameters ~= nil then
        parameters = ""
    else
        parameters = string.concat(Map(v.parameters, tostring), ", ")
    end
    return string.format([[fn(%s){
        %s
    }
    ]], parameters, v.body)
end

MError = MObject:extend()
MError.className = "MError"
MError.__tostring = function(v)
    return string.format("ERROR: %s", v.message)
end

MString = MValue:extend(Hashable)
MString.className = "MString"
MString.__tostring = function(v)
    return v.value
end
MString.__add = function(left, right)
    return MString { value = left.value .. right.value }
end
MString.hashType = HashType.STRING

MHash = MObject:extend()
MHash.className = "MHash"
MHash.__tostring = function(v)
    local elements = {}
    for key, value in pairs(v.entries) do
        table.insert(elements, string.format("%s:%s", key, value))
    end
    return string.format("{%s}", table.concat(elements, ", "))
end

MBuiltinFunction = MObject:extend()
MBuiltinFunction.className = "MBuiltinFunction"
MBuiltinFunction.__tostring = function(v)
    return "builtin function"
end

MArray = MObject:extend()
MArray.className = "MArray"
MArray.__tostring = function(v)
    return string.format("[%s]", table.concat(Map(v.elements, tostring), ", "))
end

local function argSizeCheck(expectedSize, args, body)
    local length = Len(args)
    if length == expectedSize then
        return body(args)
    end
    return MError { message = string.format("wrong number of arguments. got=%s, want=%s", length, expectedSize) }
end

local function arrayCheck(name, args, body)
    local array = args[1]
    if array:is(MArray) then
        return body(array, Len(array.elements))
    end
    return MError { message = string.format("argument to `%s` must be ARRAY, got %s", name, array.className) }
end

LEN_NAME = "len"
local function len(args)
    return argSizeCheck(1, args, function(arguments)
        local arg = arguments[1]
        if arg:is(MString) then
            return MInteger { value = #arg.value }
        end
        if arg:is(MArray) then
            return MInteger { value = Len(arg.elements) }
        end
        return MError { message = string.format("argument to `len` not supported, got %s", arg.className) }
    end)
end

PUSH_NAME = "push"
local function push(args)
    return argSizeCheck(2, args, function(arguments)
        return arrayCheck(PUSH_NAME, arguments, function(array, _)
            table.insert(array.elements, args[2])
            return MArray { elements = array.elements }
        end)
    end)
end

FIRST_NAME = "first"
local function first(args)
    return argSizeCheck(1, args, function(arguments)
        return arrayCheck(FIRST_NAME, arguments, function(array, length)
            if length > 0 then
                return array.elements[1]
            end
            return M_NULL
        end)
    end)
end

LAST_NAME = "last"
local function last(args)
    return argSizeCheck(1, args, function(arguments)
        return arrayCheck(LAST_NAME, arguments, function(array, length)
            if length > 0 then
                return array.elements[length]
            end
            return M_NULL
        end)
    end)
end

REST_NAME = "rest"
local function rest(args)
    return argSizeCheck(1, args, function(arguments)
        return arrayCheck(REST_NAME, arguments, function(array, length)
            if length <= 0 then
                return M_NULL
            end
            table.remove(array.elements, 1)
            return MArray { elements = array.elements }
        end)
    end)
end

BUILTINS = {
    [LEN_NAME] = MBuiltinFunction { fn = len },
    [PUSH_NAME] = MBuiltinFunction { fn = push },
    [FIRST_NAME] = MBuiltinFunction { fn = first },
    [LAST_NAME] = MBuiltinFunction { fn = last },
    [REST_NAME] = MBuiltinFunction { fn = rest },
}