-- DataHoarder collects data pertaining to the current character, for use in TellMyStory
-- By: Avael @ Argent Dawn EU


-- Housekeeping
local addonName = ...
print( addonName .. " loaded." )

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
local dbDefaults = {
	"default1",
	"default2",
}
-- We use a separate frame for this
local dbLoadFrame = CreateFrame("frame", addonName..".".."dbLoadFrame")
dbLoadFrame:UnregisterAllEvents()
dbLoadFrame:RegisterEvent("ADDON_LOADED")
dbLoadFrame:RegisterEvent("PLAYER_LOGOUT")


local function initDB (self, event, ...)
	if event == "ADDON_LOADED" and ... == addonName then
		if table.getn(DataHoarderDB) == 0 or DataHoarderDB == nil then
			print("DataHoarderDB is nil/empty, loading defaults")
			DataHoarderDB = AvUtil_TableDeepCopy(dbDefaults)
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
	"PLAYER_XP_UPDATE",
}

local DHFrame = CreateFrame("frame", addonName..".".."DHFrame")
DHFrame:UnregisterAllEvents()

for i, v in ipairs( hookedEvents ) do
	DHFrame:RegisterEvent(v)
end


-- Event response / handling
local function handleEvent(self, event, ...)
	print( addonName .. " caught event: " .. event)
end

DHFrame:SetScript("OnEvent", handleEvent)



local function dbInsert(indata)
	table.insert(DataHoarderDB, indata)
end

local function dbDump()
	if table.getn(DataHoarderDB) == 0 then
		print("Nothing to dump, db empty")
		do return end
	end
	print("\n")
	print("DataHoarderDB contents:")
	for k, v in pairs( DataHoarderDB ) do
		print( k, colors.cyan, v )
	end
end

local function dbDelete(deldata)
	table.remove(DataHoarderDB, deldata)
end



-- Slash CMDs

SLASH_AVADDON1, SLASH_AVADDON2 = '/ava', '/avaddon';

local function slashHandler(msg)
	local parts = {}
	
	for part in string.lower(msg):gmatch("%S+") do
		table.insert(parts, part)
	end


	if parts[1] == 'listhooks' then
		for i, v in ipairs( hookedEvents ) do
			print( i,v )
		end
	elseif parts[1] == "dbinsert" then
		dbInsert(parts[2])
	elseif parts[1] == "dbdump" then
		dbDump()
	elseif parts[1] == "dbdelete" then
		if tonumber(parts[2]) then
			dbDelete(parts[2])
		else
			print("Delete arg cannot be blank and must be a number")
		end
	else
		print("AvAddon commands:")
		print("    listhooks")
		print("    dbInsert <arg>")
		print("    dbDelete <index>")
		print("    dbDump")
	end
end

SlashCmdList["AVADDON"] = slashHandler;