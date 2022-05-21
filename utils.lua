function Ternary(cond, T, F)
    if cond then
        return T
    else
        return F
    end
end

function Enum(array)
    local length = #array
    for i = 1, length do
        local v = array[i]
        array[v] = i
    end

    return array
end

function Map(table, body)
    local t = {}
    for k, v in pairs(table) do
        t[k] = body(v)
    end
    return t
end

function Also(value, body)
    body(value)
    return value
end