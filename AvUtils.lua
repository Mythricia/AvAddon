-- DataHoarder & TellMyStory Utilities
-- By: Avael @ Argent Dawn EU

local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"


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



-- Generates table of Continent names from the WoW API directly
-- Will always know all continents, and avoids mis-spellings
function AvUtil_GenerateContNames()
	local contList = {GetMapContinents()}
	local nameTable = {}

	for k, v in ipairs(contList) do
		if not tonumber(v) then
			table.insert(nameTable, v)
		end
	end

	print(rainbowName..": Continent Table generated from WoW API")
	
	return nameTable
end



-- Extracts the current, actual, Continent, Zone, and SubZone of the player
-- Also restores the players world map to whatever they were viewing,
-- which should make the query invisible
function AvUtil_GetPlayerMapInfos()
	
	-- Store the current world map view, in case the player is looking at different zones
	local prevMapID = GetCurrentMapAreaID()

	-- Move the world map view to the players current zone
	SetMapToCurrentZone()

	continentNames = continentNames or AvUtil_GenerateContNames()
	-- {
	-- 	[1]="Kalimdor",
	-- 	[2]="Eastern Kingdoms",
	-- 	[3]="Outland",
	-- 	[4]="Northrend",
	-- 	[5]="The Maelstrom",
	-- 	[6]="Pandaria",
	-- 	[7]="Draenor",
	-- 	[8]="Broken Isles"
	-- }

	local contID = GetCurrentMapContinent()
	local contName = continentNames[contID]
	local zone = GetMapNameByID(GetCurrentMapAreaID())
	local subzone = GetRealZoneText()
	
	-- Restore the view back to whatever the player was looking at, hopefully not interrupting them
	SetMapByID(prevMapID)
	
	return ({contName,zone ,subzone})
end



-- Check if table contains an element
function AvUtil_TableContains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end