-- DataHoarder & TellMyStory Utilities
-- By: Avael @ Argent Dawn EU

local _, addonTable = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
addonTable.AvUtil = {}

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

-- Misc. Tables and functionality related variables
local InstanceTable
local tierList
local continentNames

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

	-- Only generate table once per session, on demand
	continentNames = continentNames or GenerateContNames()

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



-- Programmatically generate list of all dungeons and raids, to be used in determining what expansion
-- the instance your are currently inside, actually belongs to.
-- Generate table of dungeon and raid instances by expansion
local function GenerateInstanceTable()
  InstanceTable = {}

  InstanceTable.trackedTypes = "party, raid"

  local numTiers = EJ_GetNumTiers()
  local numToScan = 10000


  local function EJCrawlPass(scanRaids)
    -- Bullshit Lua ternary-ish operator
    local instanceType = (scanRaids and "Raids") or ("Dungeons")

    InstanceTable[instanceType] = {}

    for t=1, numTiers do
      EJ_SelectTier(t)
      local tierName = EJ_GetTierInfo(t)
      InstanceTable[instanceType][tierName] = {}

      for i=1, numToScan do
        local id, name = EJ_GetInstanceByIndex(i, scanRaids)
        if name then
          InstanceTable[instanceType][tierName][name] = id
        end
      end
    end
  end

  -- Do one pass for raids, one pass for 5mans
  EJCrawlPass(true)
  EJCrawlPass(false)

  -- Generate a chronologically ordered list of expansion names if it doesn't exist
  if not tierList then
    tierList = {}
    for i=1, EJ_GetNumTiers() do
      tierList[i] = EJ_GetTierInfo(i)
    end
  end
end



local function GetCurrentInstanceTier()

  -- Check that the InstanceTable even exists, if not, create it
  if not InstanceTable then
    GenerateInstanceTable()
  end

  -- Bail out if we're not even in an instance!
  if not IsInInstance() then do return "NotAnInstance" end end


  local _, instanceType, difficultyID = GetInstanceInfo()
  local zoneName = GetRealZoneText()

  -- Determine the search key to be used. This should be refactored somehow.
  -- Lua ternary-ish bullshit
  local searchType = (instanceType == "party" and "Dungeons") or ("Raids")

  -- First, check if we even track this type of instance, if not, bail out
  if not string.find(InstanceTable.trackedTypes, instanceType) then return "UnknownInstanceType" end

  -- Second, is it Heroic? If so, skip all of Vanilla. Else, search the entire instance table
  -- Use another strikingly confusing Lua ternary-ish boolean bullshit operator for this
  local startIndex = (difficultyID == 2 and 2) or (1)

  -- Perform the actual search, scanning by instance name, skipping Classic if we're in Heroic
  -- Can't scan using instanceID, since the Encounter Journal is not ready during loading screen, and can't return it
  -- Also can't use the name returned by GetInstanceInfo() since it's inconsistent. GetRealZoneText() seems more accurate for instances.
  for i = startIndex, #tierList do
    local subTable = InstanceTable[searchType][tierList[i]]

    for k, v in pairs(subTable) do
      if (zoneName == k) then
        return tierList[i]
      end
    end
  end
  -- Fallthrough return
  return "UnknownTier"
end


-- Push all the utilities to the addonTable
addonTable.AvUtil.TableContains = TableContains
addonTable.AvUtil.ppTable = ppTable
addonTable.AvUtil.GetPlayerMapInfos = GetPlayerMapInfos
addonTable.AvUtil.GenerateContNames = GenerateContNames
addonTable.AvUtil.FormatDecimalString = FormatDecimalString
addonTable.AvUtil.AvColors = AvColors
addonTable.AvUtil.GetCurrentInstanceTier = GetCurrentInstanceTier
