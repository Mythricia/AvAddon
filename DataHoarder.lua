-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU

-- Local vars
local addonName = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
local doEventSpam = false
local verboseErrors = false
local isAddonLoaded = false
local inCombat = false


-- This shouldn't be here, but it's here, so that I don't get a nil error when initializing DB later...
DataHoarderDB = DataHoarderDB or {}


-- Cache some common functions
-- Common lua:
local table_insert = table.insert;
local type = type;
local pairs = pairs
local ipairs = ipairs
local _G = _G
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
local cTag = "|cFF"	-- Separate the tag and Alpha (always FF) from the actual hex color definitions
local color = {
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
-- This function can also be called ingame by /ava dbDefaults
local function dbLoadDefaults()
-- Use the wipe() function supplied by the WoWLua API -
-- This wipes the table but keeps all references to it intact
wipe(DataHoarderDB)

DataHoarderDB.Character = UnitName("player")
DataHoarderDB.LastContinent = ""
DataHoarderDB.LastZone = ""
DataHoarderDB.ContinentsVisited = 0;
DataHoarderDB.ZonesVisited = 0;
DataHoarderDB.Continents = {};
DataHoarderDB.DPS = 0;
end


-- Check if addon has been fully loaded, we use a separate frame for this
-- TODO: Should re-use a single frame throughout this application

local dbLoadFrame = CreateFrame("frame", addonName..".".."dbLoadFrame")
dbLoadFrame:UnregisterAllEvents()
dbLoadFrame:RegisterEvent("ADDON_LOADED")

-- We're loaded, check if DB needs to be initialized, if so load defaults; else continue as normal
local function initDB (self, event, ...)
	if event == "ADDON_LOADED" and ... == addonName then
		isAddonLoaded = true
		print( rainbowName .. " loaded. ".."\nUse "..color.cyan.."/ava spam|r to see logging activity."..
			"\nUse "..color.cyan.."/ava|r to see options "..color.red.."(beware dragons)\n");
		
		-- Table gynmastics to find out whether database is actually populated (count num of Keys, can't rely on #length)
		-- If not, load the defaults
		local function dbSize()
			local i = 0
			for k, v in pairs(DataHoarderDB) do
				i = i + 1
			end
			return i
		end
		
		if (dbSize() == 0) then
			print("DataHoarderDB is "..color.red.."nil/empty, |rloading defaults")
			dbLoadDefaults()
		else
			print("Good news everyone, "..color.green.."DataHoarderDB was not empty!")
		end
	end
end

-- Register the db init to our addon load frame
dbLoadFrame:SetScript("OnEvent", initDB)



---------------------BEGIN---------------------
-- -- Individual event handling functions -- --
-----------------------------------------------
-- Event hook table, init as empty!
local hookedEvents = {}


-- Zone change, collect continent and zone information and count number of visits
function hookedEvents.ZONE_CHANGED_NEW_AREA(...)
	
	print(...)
	local cont = au_getPMapInfos()[1];
	local zone = au_getPMapInfos()[2];
	if doEventSpam then
		print (color.cyan .. "Character location: " .. color.red .. cont..color.green.." > "..color.red..zone)
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
	
	-- Tell the event dispatcher we've handled the event
	return true
end



hookedEvents.PLAYER_ENTERING_WORLD = function(...)
--- handle this event
end



hookedEvents.COMBAT_LOG_EVENT_UNFILTERED = function(...)
--- handle this event
end



hookedEvents.PLAYER_REGEN_DISABLED = function(...)
--- handle this event
end



hookedEvents.PLAYER_REGEN_ENABLED = function(...)
--- handle this event
end

----------------------END----------------------
-- -- Individual event handling functions -- --
-----------------------------------------------


-- Create frame, unregister all events in case we're re-using a frame, finally register all listed events 
local DHFrame = CreateFrame("frame", addonName..".".."DHFrame")
DHFrame:UnregisterAllEvents()

for k, v in pairs( hookedEvents ) do
	DHFrame:RegisterEvent(k)
end


-- Event catcher / handler dispatcher, aslo works as a generic event handler (called on every registered event caught regardless of type)
local function catchEvent(self, event, ...)
	
	-- Check if we should enable verbose output
	if doEventSpam then
		print( color.cyan .. addonName .. " caught event: " .. color.red .. event)
		for k, v in pairs( {...} ) do
			print( color.cyan, k, color.red, v )
		end
	end
	
	
	-- Call the relevant event handler function if defined, else throw error (if verboseErrors enabled)
	if (hookedEvents[event] == nil or hookedEvents[event](unpack({...})) == nil) and verboseErrors then
		local errString = (color.red.."DataHoarder:: No event handler for:\n"..color.orange..event)
		print(errString)
		error(errString)
	end
end


-- Subscribe to OnEvent updates, using our frame and event catcher
DHFrame:SetScript("OnEvent", catchEvent)



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
	
	
	local function dumpTbl (tbl, indent)
		local indent = indent or 0
		for k, v in pairs(tbl) do
			formatting = string.rep(color.purple .. "| - - ", indent) .. color.teal .. tostring(k)
			if type(v) == "table" then
				print(formatting .. color.green .. " +")
				dumpTbl(v, indent+1)
			else
				print(formatting .. ": " .. color.cyan .. tostring(v))
			end
		end
	end
	
	dumpTbl(DataHoarderDB)
end


-- dbDelete
local function dbDelete(deldata)
	table.remove(DataHoarderDB, deldata)
end


-- Horrible debug function that can do anything at any time
local function runDebugFunction()
	print(color.pink.. "Nope.")
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
		"dfunc   "..color.red.."--MAY DO ANYTHING, DEBUG FUNCTION",
		"spam",
		"verboseErrors"
	}
	
	local parts = {}
	local cmd
	
	for part in string.lower(msg):gmatch("%S+") do
		table.insert(parts, part)
	end

	cmd = parts[1]

	if cmd == 'listhooks' then
		for k, v in pairs( hookedEvents ) do
			print( color.red, v )
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
		print(color.cyan.."DataHoarderDB"..color.red.." wiped.")
	elseif cmd == "spam" then
		doEventSpam = not doEventSpam
		if doEventSpam then
			print(rainbowName..": Event spam "..color.red.."enabled")
		else
			print(rainbowName..": Event spam "..color.green.."disabled")
		end
	elseif cmd == "verboseerrors" then
		verboseErrors = not verboseErrors
		if verboseErrors then
			print(rainbowName..": Verbose error logging "..color.red.."enabled")
		else
			print(rainbowName..": Verbose error logging "..color.green.."disabled")
		end
	else
		print(rainbowName.." commands:")
		for k, v in pairs( slashList ) do
			print( color.orange, v )
		end
	end
end

SlashCmdList["AVADDON"] = slashHandler;