-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU

-- Local vars
local addonName, addonTable = ...
local rainbowName = "|cFF9400D3A|r|cFF4B0082v|r|cFFEE1289A|r|cFF00FF00d|r|cFFFFFF00d|r|cFFFF7F00o|r|cFFFF0000n|r"
local doEventSpam = false
local doVerboseErrors = false
local isAddonLoaded = false
local inCombat = false
local combatTimeTracker = {["start"]=0,["stop"]=0}
local currentPlayerLevel = 0

-- Debug, damage logging accumulator
local combatDamage = 0


-- This shouldn't be here, but it's here, so that I don't get a nil error when initializing DB later...
DataHoarderDB = DataHoarderDB or {}


-- Cache some common functions
-- Common lua:
local table = table
local type = type
local pairs = pairs
local ipairs = ipairs
local string = string
local wipe = wipe
local print = print
local tostring = tostring
local tonumber = tonumber

-- AvUtils
local au_genContNames = addonTable.AvUtil.GenerateContNames
local au_getPMapInfos = addonTable.AvUtil.GetPlayerMapInfos	-- {contName, zone, subzone}
local au_strFmt = addonTable.AvUtil.FormatDecimalString
local au_ppTable = addonTable.AvUtil.ppTable
local AvColors = addonTable.AvColors


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
	CombatTime = --- Rolling total time _in combat_

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
		print( rainbowName .. " loaded. ".."\nUse "..AvColors.cyan.."/ava spam|r to see logging activity."..
		"\nUse "..AvColors.cyan.."/ava|r to see options "..AvColors.red.."(beware dragons)\n");

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
			print("DataHoarderDB is "..AvColors.red.."nil/empty, |rloading defaults")
			dbLoadDefaults()
		else
			print("Good news everyone, "..AvColors.green.."DataHoarderDB was not empty!")
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

	if IsInInstance() then
		-- Use GetRealZoneText() for zone name, it's more consistent than what GetInstanceInfo() returns
		local instanceName = GetRealZoneText()
		local instanceTier = tostring(addonTable:GetCurrentInstanceTier())
		if not DataHoarderDB.Dungeons then DataHoarderDB.Dungeons = {} end

		DataHoarderDB.Dungeons[instanceTier] = DataHoarderDB.Dungeons[instanceTier] or {}
		DataHoarderDB.Dungeons[instanceTier][instanceName] = DataHoarderDB.Dungeons[instanceTier][instanceName] or {}

		if DataHoarderDB.Dungeons[instanceTier][instanceName].Visits then
			DataHoarderDB.Dungeons[instanceTier][instanceName].Visits = DataHoarderDB.Dungeons[instanceTier][instanceName].Visits + 1
			if doEventSpam then
				print("Already visited "..instanceName.." "..DataHoarderDB.Dungeons[instanceTier][instanceName].Visits-1 .. " times")
			end
		else
			DataHoarderDB.Dungeons[instanceTier][instanceName].Visits = 1
			if doEventSpam then
				print("First visit to "..instanceName.."!")
			end
		end
	else

		local cont = au_getPMapInfos()[1];
		local zone = au_getPMapInfos()[2];
		if doEventSpam then
			print (AvColors.cyan .. "Character location: " .. AvColors.red .. cont..AvColors.green.." > "..AvColors.red..zone)
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
	-- Tell the event dispatcher we've handled the event
	return true
end



-- log current level on login, if it's not already in the db
function hookedEvents.PLAYER_ENTERING_WORLD(...)
	currentPlayerLevel = UnitLevel("player")

	if not DataHoarderDB.LevelData then
		DataHoarderDB.LevelData = {}
	end

	if not DataHoarderDB.LevelData[currentPlayerLevel] then
		DataHoarderDB.LevelData[currentPlayerLevel] = {}
	end

	if not DataHoarderDB.LevelData[currentPlayerLevel].EntryTime then
		DataHoarderDB.LevelData[currentPlayerLevel].EntryTime = time()
	end
end



-- Log the new level when the player levels up
-- The level returned in event arg 1 is more accurate than UnitLevel("player") at this instant!
function hookedEvents.PLAYER_LEVEL_UP(...)
	local level, hp, mp, talentPoints, str, agi, stam, int, spirit = ...

	-- Safeguard in case last level was actually level 1
	local lastLevel = max(tonumber(level)-1, 1)

	-- Update the local level variable right away, since UnitLevel("player") is inaccurate at this instant
	currentPlayerLevel = level

	if doEventSpam then
		print( "Player leveled up, new level is " .. level )
		print( "Gained ".. hp.."HP")
		print( "Gained ".. mp .."Mana")
	end

	-- Create DB entry for the new level
	-- TODO: Panic if the level entry already exists, or do we not care? Check if it's empty before overwrite?
	if not DataHoarderDB.LevelData then
		DataHoarderDB.LevelData = {}
	end

	if not DataHoarderDB.LevelData[level] then
		DataHoarderDB.LevelData[level] = {}
	end


	-- Go back and set the ExitTime for the previous level
	DataHoarderDB.LevelData[lastLevel].ExitTime = time()

	-- Set the EntryTime for the level we just became
	DataHoarderDB.LevelData[level].EntryTime = time()

	-- FIXME: Currently represents REAL WORLD TIME; not /played time or anything contextual.
	-- calculate the time we spent in the last level, safeguard in case last level is missing db entry
	local lastLevelTime = DataHoarderDB.LevelData[lastLevel].ExitTime - (DataHoarderDB.LevelData[lastLevel].EntryTime or 0)
	print (AvColors.pink.."Last level took "..SecondsToTime(lastLevelTime, false, false, 6))

	-- Calculate the average DPS for the last level
	local averageDPS = DataHoarderDB.LevelData[lastLevel].DamageTotal / DataHoarderDB.LevelData[lastLevel].CombatTime
	local combatTime = DataHoarderDB.LevelData[lastLevel].CombatTime
	DataHoarderDB.LevelData[lastLevel].AvgDPS = averageDPS

	print(AvColors.pink.."During the previous level, you spent "..SecondsToTime(combatTime, false, false, 6).." in combat, and did an average of "..au_strFmt(averageDPS, 0).." Damage Per Second!")
end



function hookedEvents.COMBAT_LOG_EVENT_UNFILTERED(...)
	if inCombat then
		local player = UnitName("player")

		-- Cache the first 11 args, since they will always appear
		local timeStamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags,
		sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

		if (sourceName == player) or (sourceFlags == 4369) then

			-- Check if we're dealing with Spell or Ranged damage first, since both share argument structure
			if (eventType == "SPELL_DAMAGE") or (eventType == "RANGE_DAMAGE") or (eventType == "SPELL_PERIODIC_DAMAGE") then

				-- It's spell or ranged, so parameters are 12(spellID), 13(spellName), 14(spellSchool), the rest (15th onwards) are damage details
				local spellId, spellName, spellSchool, amount,
				overkill, school, resisted, blocked, absorbed,
				critical, glancing, crushing = select(12, ...)

				-- Increment the damage accumulator
				combatDamage = combatDamage + amount

				-- Check if we're dealing with a melee swing
			elseif eventType == "SWING_DAMAGE" then

				-- It's melee, no prefix parameters, all extra args are damage details
				local amount, overkill, school, resisted,
				blocked, absorbed, critical, glancing, crushing = select(12, ...)

				-- Increment the damage accumulator
				combatDamage = combatDamage + amount
			end
		end
	end
end



function hookedEvents.PLAYER_REGEN_DISABLED(...)

	-- We're in combat, set state and log enter timestamp
	combatTimeTracker.start = GetTime()
	combatDamage = 0
	inCombat = true
end



function hookedEvents.PLAYER_REGEN_ENABLED(...)

	-- We're out of combat, unset state and log exit timestamp
	combatTimeTracker.stop = GetTime()
	inCombat = false

	DataHoarderDB.LevelData[currentPlayerLevel].CombatTime = (DataHoarderDB.LevelData[currentPlayerLevel].CombatTime or 0) + (combatTimeTracker.stop - combatTimeTracker.start)

	DataHoarderDB.LevelData[currentPlayerLevel].DamageTotal = (DataHoarderDB.LevelData[currentPlayerLevel].DamageTotal or 0) + combatDamage
	print(AvColors.red.."DBDH:: Added "..tostring(combatDamage).." damage to totals.")

	combatDamage = 0
end

----------------------END----------------------
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
		print( AvColors.cyan .. addonName .. " caught event: " .. AvColors.red .. event)
		for k, v in pairs( {...} ) do
			print( AvColors.cyan, k, AvColors.red, v )
		end
	end


	-- Call the relevant event handler function if defined, else throw error (if doVerboseErrors enabled)
	if (hookedEvents[event] == nil or hookedEvents[event](unpack({...})) == nil) and doVerboseErrors then
		local errString = (AvColors.red.."DataHoarder:: No event handler for:\n"..AvColors.orange..event)
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
			print( AvColors.red, k )
		end
	end,

	desc = "Lists all registered events"
}


slashCommands.dbwipe = {
	func = function(...)
		wipe(DataHoarderDB)
		print(AvColors.cyan.."DataHoarderDB"..AvColors.red.." wiped.")
	end,

	desc = "Wipes database clean, without deleting the actual db"
}


slashCommands.spam = {
	func = function(...)
		doEventSpam = not doEventSpam
		if doEventSpam then
			print(rainbowName..": Event spam "..AvColors.red.."enabled")
		else
			print(rainbowName..": Event spam "..AvColors.green.."disabled")
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

		au_ppTable(DataHoarderDB)
	end,

	desc = ("Print the "..AvColors.red.."entire DataHoarder database for this character!")
}


slashCommands.dfunc = {
	func = function(...)
		print(AvColors.pink.. "Nope.")
	end,

	desc = ("Debug function - "..AvColors.red.."MAY DO ANYTHING")
	}


	slashCommands.verboseerrors = {
		func = function(...)
			doVerboseErrors = not doVerboseErrors
			if doVerboseErrors then
				print(rainbowName..": Verbose error logging "..AvColors.red.."enabled")
			else
				print(rainbowName..": Verbose error logging "..AvColors.green.."disabled")
			end
		end,

		desc = "Toggles extra verbose error logging"
	}



	slashCommands.wipelevel = {
		func = function(...)
			local targLevel = ...

			if targLevel == nil then targLevel = currentPlayerLevel end

			if DataHoarderDB.LevelData[targLevel] then
				DataHoarderDB.LevelData[targLevel] = nil
				DataHoarderDB.LevelData[targLevel] = {}
			end
		end,

		desc = "Wipe db records for the specified level"
	}


	-- FIXME: This is horrible, please put it out of its misery
	slashCommands.dumplevel = {
		func = function(...)

			local function doDump(lvl)

				print(" ")
				print("LevelData for level "..lvl..":")

				au_ppTable(DataHoarderDB.LevelData[lvl])
			end

			local dumpLvl = nil

			if ... then
				if pcall(tonumber,...) then
					dumpLvl = tonumber(...)
					if DataHoarderDB.LevelData[dumpLvl] then
						doDump(dumpLvl)
					else
						print( AvColors.red.."Not a valid level: |r".. ...)
					end
				else
					print( AvColors.red.."Not a valid level: |r".. ...)
				end
			else
				doDump(currentPlayerLevel)
			end

		end,

		desc = "Dump the LevelData for this level only (defaults to current level)"
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
					print(AvColors.cyan..slashListSeparator..AvColors.orange..v.desc)
				else
					print(slashListSeparator..AvColors.red.."NoDesc")
				end
			end
		end


		-- Check if the root command exists, and call it. Else print error and list available commands + their description (if any)
		if slashCommands[root] ~= nil then
			slashCommands[root].func(unpack(parts))
		elseif root == nil then
			printCmdList()
		else
			print(" ")
			print(rainbowName.." unrecognized command: "..AvColors.red..root)
			print("List available commands with "..AvColors.cyan.."/ava|r or "..AvColors.cyan.."/avaddon")
		end
	end


	SlashCmdList["AVADDON"] = slashHandler;
