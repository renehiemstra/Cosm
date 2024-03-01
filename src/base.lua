local Base = {}

function Base.esc(string)
  return "\""..string.."\""
end

function Base.haskeyoftype(set, key, mytype)
  if type(set[key])==mytype then
	return true
  else
	return false
  end
end

function Base.getsortedkeys(set)
  local keys = {}
  for key,value in pairs(set) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

function Base.serialize(o, n)
  if type(o) == "number" then
      io.write(o, ",\n")
  elseif type(o) == "string" then
      io.write(string.format("%q", o), ",\n")
  elseif type(o) == "table" then
      io.write("{\n")
      for k,v in pairs(o) do
          io.write(string.rep("    ", n), k, " = ")
          Base.serialize(v, n+1)
          --io.write(",\n")
      end
      io.write(string.rep("    ", n-1).."},\n")
  else
      error("cannot serialize a " .. type(o))
  end
end

return Base