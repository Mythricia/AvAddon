-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU

-- Local vars
local addonName = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
local doEventSpam = false
local isAddonLoaded = false
local inCombat = false

-- This shouldn't be here, but it's here, so that I don't get a nil error when initializing DB below...
DataHoarderDB = DataHoarderDB or {}



-- Cache some common functions
-- Common lua:
local table_insert = table.insert;
local type = type;
local string_len = string.len;
local string_sub = string.sub;
local string_gsub = string.gsub;
local string_format = string.format;
local string_match = string.match;

-- AvUtils
local au_genContNames = AvUtil_GenerateContNames;
local au_getPMapInfos = AvUtil_GetPlayerMapInfos;	-- {contName, zone, subzone}
local au_strFmt = AvUtil_FormatDecimalString;



-- Pretty colors
local cTag = "|cFF"

local colors = {
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


-- Load DH database if it exists for this character, if not, create it and load defaults
-- dbLoadDefaults
local function dbLoadDefaults()
-- Use the wipe() function supplied by the WoWLua API -
-- This wipes the table but keeps all references to it intact
DataHoarderDB.Character = UnitName("player")
DataHoarderDB.LastContinent = ""
DataHoarderDB.LastZone = ""
DataHoarderDB.ContinentsVisited = 0;
DataHoarderDB.ZonesVisited = 0;
DataHoarderDB.Continents = {};
DataHoarderDB.DPS = 0;
end


-- We use a separate frame for this
local dbLoadFrame = CreateFrame("frame", addonName..".".."dbLoadFrame")
dbLoadFrame:UnregisterAllEvents()
dbLoadFrame:RegisterEvent("ADDON_LOADED")
dbLoadFrame:RegisterEvent("PLAYER_LOGOUT")


local function initDB (self, event, ...)
	if event == "ADDON_LOADED" and ... == addonName then
		isAddonLoaded = true
		print( rainbowName .. " loaded. ".."\nUse "..colors.cyan.."/ava spam|r to see logging activity."..
			"\nUse "..colors.cyan.."/ava|r to see options "..colors.red.."(beware dragons)\n");
		
		-- Table gynmastics to find out whether it's actually initialized or not, and if not, load the defaults
		local function dbSize()
			local i = 0
			for k, v in pairs(DataHoarderDB) do
				i = i + 1
			end
			return i
		end
		
		if (dbSize() == 0) then
			print("DataHoarderDB is "..colors.red.."nil/empty, |rloading defaults")
			dbLoadDefaults()
		else
			print("Good news everyone, "..colors.green.."DataHoarderDB was not empty!")
		end
	elseif event == "PLAYER_LOGOUT" then
		print("PlayerLogout")
	end
end

dbLoadFrame:SetScript("OnEvent", initDB)



-- List of events to hook, as well as the actual hooking of said events
local hookedEvents = 
{
	e_zoneChange 	= "ZONE_CHANGED_NEW_AREA",
	e_playerEnter 	= "PLAYER_ENTERING_WORLD",
	e_combatLogUnf 	= "COMBAT_LOG_EVENT_UNFILTERED",
	e_startCombat 	= "PLAYER_REGEN_DISABLED",
	e_endCombat 	= "PLAYER_REGEN_ENABLED",
}

local DHFrame = CreateFrame("frame", addonName..".".."DHFrame")
DHFrame:UnregisterAllEvents()

for k, v in pairs( hookedEvents ) do
	DHFrame:RegisterEvent(v)
end


-------------------------------------------------------------
-- Event response / handling
local function handleEvent(self, event, ...)
	
	if doEventSpam == true then
		print( colors.cyan .. addonName .. " caught event: " .. colors.red .. event)
		local varArgs = {...}
		for k, v in pairs( varArgs ) do
			print( colors.cyan, k, colors.red, v )
		end
	end
	
	if event == hookedEvents.e_zoneChange then
		local cont = au_getPMapInfos()[1];
		local zone = au_getPMapInfos()[2];
		if doEventSpam then
			print (colors.cyan .. "Character location: " .. colors.red .. cont..colors.green.." > "..colors.red..zone)
		end
		
		if DataHoarderDB.LastContinent ~= cont then
			DataHoarderDB.LastContinent = cont
			
			if DataHoarderDB.Continents[cont] == nil then 
				if doEventSpam then
					print("First visit to "..cont.."!")
				end
				DataHoarderDB.Continents[cont] = {}
				DataHoarderDB.Continents[cont].Visits = 1
				DataHoarderDB.ContinentsVisited = DataHoarderDB.ContinentsVisited + 1
			else
				DataHoarderDB.Continents[cont].Visits = DataHoarderDB.Continents[cont].Visits + 1
				if doEventSpam then
					print("Already visited "..cont.." "..DataHoarderDB.Continents[cont].Visits-1 .. " times")
				end
			end
		end
		
		
		if DataHoarderDB.LastZone ~= zone then
			DataHoarderDB.LastZone = zone
			
			if DataHoarderDB.Continents[cont][zone] == nil then
				if doEventSpam then
					print("First visit to "..zone.."!")
				end
				DataHoarderDB.Continents[cont][zone] = {}
				DataHoarderDB.Continents[cont][zone].Visits = 1
				DataHoarderDB.ZonesVisited = DataHoarderDB.ZonesVisited + 1
			else
				DataHoarderDB.Continents[cont][zone].Visits = DataHoarderDB.Continents[cont][zone].Visits + 1
				if doEventSpam then
					print("Already visited "..zone.." "..DataHoarderDB.Continents[cont][zone].Visits-1 .. " times")
				end
			end
		end
	end
end
-------------------------------------------------------------

-- Register frame for Event updates
DHFrame:SetScript("OnEvent", handleEvent)



-- Slash CMD function implementations
-- dbInsert
local function dbInsert(indata)
	table.insert(DataHoarderDB, indata)
end

-- dbDump
local function dbDump()
	if next(DataHoarderDB) == nil then
		print("Nothing to dump, db empty")
		do return end
	end
	print("\n")
	print("DataHoarderDB contents:")
	for k, v in pairs( DataHoarderDB ) do
		print( k, colors.cyan, v )
	end
end

-- dbDelete
local function dbDelete(deldata)
	table.remove(DataHoarderDB, deldata)
end


-- Horrible debug function that can do anything at any time
local function runDebugFunction()
	print(colors.pink.. "Nope.")
end


-- Slash CMDs
SLASH_AVADDON1, SLASH_AVADDON2 = '/ava', '/avaddon';

local function slashHandler(msg)
	local slashList = {
		"listhooks",
		"dbInsert",
		"dbDelete",
		"dbDefaults",
		"dbDump",
		"dbWipe",
		"dfunc   "..colors.red.."--MAY DO ANYTHING, DEBUG FUNCTION",
		"spam",
	}
	
	local parts = {}
	local cmd
	
	for part in string.lower(msg):gmatch("%S+") do
		table.insert(parts, part)
	end

	cmd = parts[1]

	if cmd == 'listhooks' then
		for k, v in pairs( hookedEvents ) do
			print( colors.red, v )
		end
	elseif cmd == "dfunc" then
		runDebugFunction()
	elseif cmd == "dbinsert" then
		dbInsert(parts[2])
	elseif cmd == "dbdump" then
		dbDump()
	elseif cmd == "dbdelete" then
		if tonumber(parts[2]) then
			dbDelete(parts[2])
		else
			print("Delete arg cannot be blank and must be a number")
		end
	elseif cmd == "dbdefaults" then
		dbLoadDefaults()
	elseif cmd == "dbwipe" then
		wipe(DataHoarderDB)
		print(colors.cyan.."DataHoarderDB"..colors.red.." wiped.")
	elseif cmd == "spam" then
		doEventSpam = not doEventSpam
		if doEventSpam then
			print(rainbowName..": Event spam "..colors.red.."enabled")
		else
			print(rainbowName..": Event spam "..colors.green.."disabled")
		end
	else
		print(rainbowName.." commands:")
		for k, v in pairs( slashList ) do
			print( colors.orange, v )
		end
	end
end

SlashCmdList["AVADDON"] = slashHandler;