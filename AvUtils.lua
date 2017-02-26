-- DataHoarder & TellMyStory Utilities
-- By: Avael @ Argent Dawn EU

local _, addonTable = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
addonTable.AvUtil = {}
local continentNames

-- Pretty color tags
local cTag = "|cFF"	-- Separate the tag and Alpha (always FF) from the actual hex color definitions
local AvColors = {
	red 	= cTag.."FF0000",
	green	= cTag.."00FF00",
	blue	= cTag.."0000FF",
	cyan	= cTag.."00FFFF",
	teal	= cTag.."008080",
	orange	= cTag.."FFA500",
	brown	= cTag.."8B4500",
	pink	= cTag.."EE1289",
	purple	= cTag.."9F79EE",
}

-- str_FormatDecimal(float, integer)
-- Wrapper for string.format("%.nf", s) where n is number of decimal places and s is input number
local function FormatDecimalString(inputString, precision)
	assert(type(inputString) == "number", "str_FormatDecimal :: Invalid arg 1")
	assert(type(precision) == "number", "str_FormatDecimal :: Invalid arg 2")

	local fmtString = ("%."..precision.."f")

	return string.format(fmtString, inputString)
end



-- Generates table of Continent names from the WoW API directly
-- Will always know all continents, and avoids mis-spellings
local function GenerateContNames()
	local contList = {GetMapContinents()}
	local nameTable = {}

	for k, v in ipairs(contList) do
		-- GetMapContinents() returns alternating ID's and names, so 'not tonumber()' lets us easily skip the ID's
		if not tonumber(v) then
			table.insert(nameTable, v)
		end
	end

	print(rainbowName..": Continent Table generated from WoW API")

	return nameTable
end



-- Extracts the current, Continent, Zone, and SubZone of the player
-- Also restores the players world map to whatever they were viewing,
-- which should make the query invisible, despite requiring us to manipulate the world map
local function GetPlayerMapInfos()

	-- Store the current world map view, in case the player is looking at different zones
	local prevMapID = GetCurrentMapAreaID()

	-- Move the world map view to the players current zone
	SetMapToCurrentZone()

	-- Only generate table once per session
	continentNames = continentNames or GenerateContNames()
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



-- Check if table contains an element (as either key or value, or contiguous element)
local function TableContains(table, element)
   -- check for keys first for an easy win
   if table[element] ~= nil then
   	return true
   else
      -- No easy win, crawl the table values
      for k, v in pairs(table) do
      	if v == element or k == element then
      		return true
      	end
      end
      return false
  end
end


-- Table prettyprinter, recursive
local function ppTable (tbl, indent)
	local indent = indent or 0
	for k, v in pairs(tbl) do
		local formatting = string.rep(AvColors.purple .. "| - - ", indent) .. AvColors.teal .. tostring(k)
		if type(v) == "table" then
			print(formatting .. AvColors.green .. " +")
			ppTable(v, indent+1)
		else
			print(formatting .. ": " .. AvColors.cyan .. tostring(v))
		end
	end
end


addonTable.AvUtil.TableContains = TableContains
addonTable.AvUtil.ppTable = ppTable
addonTable.AvUtil.GetPlayerMapInfos = GetPlayerMapInfos
addonTable.AvUtil.GenerateContNames = GenerateContNames
addonTable.AvUtil.FormatDecimalString = FormatDecimalString
addonTable.AvColors = AvColors
