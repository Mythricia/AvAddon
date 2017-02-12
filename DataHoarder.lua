-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU

-- Local vars
local addonName = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
local doEventSpam = false
local doVerboseErrors = false
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

DataHoarderDB.Character 		= UnitName("player")
DataHoarderDB.LastContinent 	= ""
DataHoarderDB.LastZone 			= ""
DataHoarderDB.ContinentsVisited = 0
DataHoarderDB.ZonesVisited 		= 0
DataHoarderDB.Continents 		= {}
DataHoarderDB.LevelData			= {}
--[[
	1 = {
		
		Played = --- timePlayed, synced with the in-game current level /played statistic on login & logout, if possible
		AFKTime= --- timeWhileAFK
		Active = --- timePlayed - timeAFK
		AvgDPS = --- averageDPSThroughLevel
		
	}	
}
]]
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



-- log current level on login, if it's not already in the db
hookedEvents.PLAYER_ENTERING_WORLD = function(...)

if not DataHoarderDB.LevelData then
	DataHoarderDB.LevelData = {}
end

if not (DataHoarderDB.LevelData[UnitLevel("player")]) then
	DataHoarderDB.LevelData[UnitLevel("player")] = {}
end

end



-- Log the new level when the player levels up
-- The level returned in event arg 1 is more accurate than UnitLevel("player") at this instant!
hookedEvents.PLAYER_LEVEL_UP = function(...)
local level, hp, mp, talentPoints, str, agi, stam, int, spirit = ...

if doEventSpam then
	print( "Player leveled up, new level is " .. varArgs[1] )
	print( "Gained "..varArgs[2].."HP")
	print( "Gained ".. varArgs[3] .."Mana")
end

-- Create DB entry for the new level
-- TODO: Panic if the level entry already exists, or do we not care? Check if it's empty before overwrite?
if not DataHoarderDB.LevelData then
	DataHoarderDB.LevelData = {}
end

if not (DataHoarderDB.LevelData[level]) then
	DataHoarderDB.LevelData[level] = {}
end

end



hookedEvents.COMBAT_LOG_EVENT_UNFILTERED = function(...)
-- handle this event
-- This is hilarious: print(select(select('#', ...)-3,...))
end



hookedEvents.PLAYER_REGEN_DISABLED = function(...)

-- We're in combat, set state and log enter timestamp
inCombat = true

end



hookedEvents.PLAYER_REGEN_ENABLED = function(...)

-- We're out of combat, unset state and log exit timestamp
inCombat = false

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
	
	
	-- Call the relevant event handler function if defined, else throw error (if doVerboseErrors enabled)
	if (hookedEvents[event] == nil or hookedEvents[event](unpack({...})) == nil) and doVerboseErrors then
		local errString = (color.red.."DataHoarder:: No event handler for:\n"..color.orange..event)
		print(errString)
		error(errString)
	end
end


-- Subscribe to OnEvent updates, using our frame and event catcher
DHFrame:SetScript("OnEvent", catchEvent)



-----------------------------
-- -- SlashCMD Handling -- --
-----------------------------

-- Required WoW API globals for /command variants
SLASH_AVADDON1, SLASH_AVADDON2 = '/ava', '/avaddon';



-- -- SlashCMD implementations
local slashCommands = {}

slashCommands.listhooks = {
	func = function(...)
	print(" ")
	print(rainbowName.." hooked events: ")
	for k, v in pairs( hookedEvents ) do
		print( color.red, k )
	end
	end,
	
	desc = "Lists all registered events"
}

slashCommands.dbdefaults = {
	func = function(...)
	dbLoadDefaults()
	end,
	
	desc = "Initializes db structure"	
}

slashCommands.dbwipe = {
	func = function(...)
	wipe(DataHoarderDB)
	print(color.cyan.."DataHoarderDB"..color.red.." wiped.")
	end,
	
	desc = "Wipes database clean, without deleting the actual db"
}


slashCommands.spam = {
	func = function(...)
	doEventSpam = not doEventSpam
	if doEventSpam then
		print(rainbowName..": Event spam "..color.red.."enabled")
	else
		print(rainbowName..": Event spam "..color.green.."disabled")
	end
	end,
	
	desc = "Toggles verbose reporting of events"	
}


slashCommands.dbdump = {
	func = function(...)
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
	end,
	
	desc = ("Print the "..color.red.."entire DataHoarder database for this character!")
}


slashCommands.dfunc = {
	func = function(...)
	print(color.pink.. "Nope.")
	end,
	
	desc = ("Debug function - "..color.red.."MAY DO ANYTHING")
}


slashCommands.verboseerrors = {
	func = function(...)
	doVerboseErrors = not doVerboseErrors
	if doVerboseErrors then
		print(rainbowName..": Verbose error logging "..color.red.."enabled")
	else
		print(rainbowName..": Verbose error logging "..color.green.."disabled")
	end
	end,
	
	desc = "Toggles extra verbose error logging"
}



-- SlashCmd catcher/preprocessor
local function slashHandler(msg)
	
	-- split the recieved slashCmd into a root command plus any extra arguments
	local parts = {}
	local root
	
	for part in string.lower(msg):gmatch("%S+") do
		table.insert(parts, part)
	end
	
	root = parts[1]
	table.remove(parts, 1) --FIXME: Must be a better way to strip the first element of the table, or just handle the whole thing better
	
	
	-- Utility function to print all available commands
	local function printCmdList()
		local slashListSeparator = "      `- "
		
		print(" ")
		print(rainbowName.." commands:")
		
		for k, v in pairs(slashCommands) do
			print(k)
			if v.desc then
				print(color.cyan..slashListSeparator..color.orange..v.desc)
			else
				print(slashListSeparator..color.red.."NoDesc")
			end
		end
	end
	
	
	-- Check if the root command exists, and call it. Else print error and list available commands + their description (if any)
	if slashCommands[root] ~= nil then
		slashCommands[root].func(unpack({parts}))
	elseif root == nil then
		printCmdList()
	else
		print(" ")
		print(rainbowName.." unrecognized command: "..color.red..root)
		print("List available commands with "..color.cyan.."/ava|r or "..color.cyan.."/avaddon")
	end
end


SlashCmdList["AVADDON"] = slashHandler;