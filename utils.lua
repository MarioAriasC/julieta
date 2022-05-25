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

function Map(array, body)
  local t = {}
  for k, v in pairs(array) do
    t[k] = body(v)
  end
  return t
end

function Also(value, body)
  body(value)
  return value
end

function ForEach(array, body)
  for i = 1, #array do
    body(array[i])
  end
end

function ForEachIndexed(array, body)
  for k, v in pairs(array) do
    body(k, v)
  end
end

function Keys(map)
  local keys = {}
  for k, v in pairs(map) do
    table.insert(keys, k)
  end
  return keys
end

function Len(tbl)
  return #Keys(tbl)
end

