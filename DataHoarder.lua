-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU



-- Housekeeping
local addonName = ...
print( addonName .. " loaded." )
local doEventSpam = false
local addonLoaded = false

DataHoarderDB = DataHoarderDB or {}

-- Pretty colors
local cTag = "|cFF"

local colors = {
	red 	= cTag.."FF0000",
	green	= cTag.."00FF00",
	blue	= cTag.."0000FF",
	cyan	= cTag.."00FFFF",
	teal	= cTag.."000808",
	orange	= cTag.."FFA500",
	brown	= cTag.."8B4500",
	pink	= cTag.."EE1289",
	purple	= cTag.."9F79EE",
}


-- Load DH database if it exists for this character, if not, create it and load defaults
--[[
local dbDefaults = {
	
	["ContinentsVisited"] = 0,
	
	["Continents"] = {
		
		},
		
		["DPS"] = 0,
	},
	]]

-- dbLoadDefaults
local function dbLoadDefaults()
-- Use the wipe() function supplied by the WoWLua API -
-- This wipes the table but keeps all references to it intact
wipe(DataHoarderDB)
DataHoarderDB.LastContinent = ""
DataHoarderDB.ContinentsVisited = 0;
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
		addonLoaded = true
		if next(DataHoarderDB) == nil then
			print("DataHoarderDB is nil/empty, loading defaults")
			dbLoadDefaults()
		else
			print("DataHoarderDB was not empty!")
		end
	elseif event == "PLAYER_LOGOUT" then
		print("PlayerLogout")
	end
end

dbLoadFrame:SetScript("OnEvent", initDB)



-- List of events to hook, as well as the actual hooking of said events
local hookedEvents = 
{
	e_playerXP = 	{"PLAYER_XP_UPDATE"},
	e_zoneChange = 	{"ZONE_CHANGED_NEW_AREA"},
	e_bagOpen = 	{"BAG_UPDATE"},
	e_chatXPMsg = 	{"CHAT_MSG_COMBAT_XP_GAIN"},
	e_playerEnter = {"PLAYER_ENTERING_WORLD"},
}

local DHFrame = CreateFrame("frame", addonName..".".."DHFrame")
DHFrame:UnregisterAllEvents()

for k, v in pairs( hookedEvents ) do
	DHFrame:RegisterEvent(v[1])
end


-------------------------------------------------------------
-- Event response / handling
local function handleEvent(self, event, ...)
	if doEventSpam == true then
		print("\n")
		print( addonName .. " caught event: " .. event)
		local varArgs = {...}
		for k, v in pairs( varArgs ) do
			print( colors.cyan, k, colors.red, v )
		end
	end
	
	if event == hookedEvents.e_zoneChange[1] then
		local cont = AvUtil_GetPlayerMapInfos()[1]
		if DataHoarderDB.LastContinent == cont then
			do return end
		end
		
		DataHoarderDB.LastContinent = cont
		if DataHoarderDB.Continents[cont] == nil then 
			print("First visit to "..cont.."!")
			DataHoarderDB.Continents[cont] = {}
			DataHoarderDB.Continents[cont].Visits = 1
			DataHoarderDB.ContinentsVisited = DataHoarderDB.ContinentsVisited + 1
		else
			DataHoarderDB.Continents[cont].Visits = DataHoarderDB.Continents[cont].Visits + 1
			print("Already visited "..cont.." "..DataHoarderDB.Continents[cont].Visits-1 .. " times")
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
	-- print"No dbfunc implemented right now"
	
	-- local locString = ""
	-- for k, v in pairs( AvUtil_GetPlayerMapInfos() ) do
	-- 	-- print( k,v )
	-- 	locString = locString..v..", "
	-- end
	-- print(locString)
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
			print( colors.red, v[1] )
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
	elseif cmd == "spam" then
		doEventSpam = not doEventSpam
		if doEventSpam then
			print("AvAddon: Event spam "..colors.red.."enabled")
		else
			print("AvAddon: Event spam "..colors.green.."disabled")
		end
	else
		print("AvAddon commands:")
		for k, v in pairs( slashList ) do
			print( colors.orange, v )
		end
	end
end

SlashCmdList["AVADDON"] = slashHandler;