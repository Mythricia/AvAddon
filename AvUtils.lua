-- DataHoarder & TellMyStory Utilities
-- By: Avael @ Argent Dawn EU

-- str_FormatDecimal(float, integer)
-- Wrapper for string.format("%.nf", s) where n is number of decimal places and s is input string
function AvUtil_FormatDecimalString(inputString, precision)
	assert(type(inputString) == "number", "str_FormatDecimal :: Invalid arg 1")
	assert(type(precision) == "number", "str_FormatDecimal :: Invalid arg 2")
	
	local fmtString = ("%."..precision.."f")
	
	return string.format(fmtString, inputString)
end


-- Deep table copy function, returns a new table identical to <o>
-- DO NOT pass a second argument, it is used recursively by the copy
function AvUtil_TableDeepCopy(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end


  local no = {}
  seen[o] = no
  setmetatable(no, AvUtil_TableDeepCopy(getmetatable(o), seen))

  for k, v in next, o, nil do
    k = (type(k) == 'table') and k:AvUtil_TableDeepCopy(seen) or k
    v = (type(v) == 'table') and v:AvUtil_TableDeepCopy(seen) or v
    no[k] = v
  end
  return no
end