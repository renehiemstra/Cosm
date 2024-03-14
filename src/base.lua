local Base = {}

function Base.esc(string)
  return "\""..string.."\""
end

function Base.mark_as_array(t)
  setmetatable(t, {__isarray = true})
end

function Base.mark_as_table(t)
  setmetatable(t, {__isarray = false})
end

--general keys require access set[key] and do not
--allow pretty serialization
function Base.mark_as_general_keys(t)
  setmetatable(t, {__simplekeys = false})
end

--simple keys allow access like set.key and allow
--pretty serialization
function Base.mark_as_simple_keys(t)
  setmetatable(t, {__simplekeys = true})
end

function Base.getcustommetatable(t)
  local mt = getmetatable(t)
  if mt==nil then
    Base.mark_as_table(t)
    Base.mark_as_general_keys(t)
    return getmetatable(t)
  else
    return mt
  end
end

-- use this when serializing
function Base.is_array(t)
  local mt = Base.getcustommetatable(t)
  return mt.__isarray==true
end

-- use this when serializing
function Base.has_simple_keys(t)
  local mt = Base.getcustommetatable(t)
  return mt.__simplekeys==true
end

function Base.haskeyoftype(set, key, mytype)
  if type(set[key])==mytype then
	  return true
  else
	  return false
  end
end

--count number of elements of a table
function Base.length(table)
  local count = 0
  for i,v in pairs(table) do
    count = count + 1
  end
  return count
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
  if type(o) == "boolean" then
    io.write(string.format("%s", o), ",\n")
  elseif type(o) == "number" then
    io.write(o, ",\n")
  elseif type(o) == "string" then
    io.write(string.format("%q", o), ",\n")
  elseif type(o) == "table" then
    io.write("{\n")
    if Base.is_array(o) then --if marked as an array
      for _,v in ipairs(o) do
        io.write(string.rep("    ", n))
        Base.serialize(v, n+1)
      end
    else  --regular table or hashtable
      local sortedkeys = Base.getsortedkeys(o)
      if Base.has_simple_keys(o) then
        for _,key in ipairs(sortedkeys) do
          io.write(string.rep("    ", n), key, " = ")
          Base.serialize(o[key], n+1)
        end
      else
        for _,key in ipairs(sortedkeys) do
          io.write(string.rep("    ", n), "[\"", key, "\"] = ")
          Base.serialize(o[key], n+1)
        end
      end
    end
    io.write(string.rep("    ", n-1).."},\n")
  else
    error("cannot serialize a " .. type(o))
  end
end

return Base