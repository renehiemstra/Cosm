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

return Base