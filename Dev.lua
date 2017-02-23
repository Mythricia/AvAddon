-- For hotloading test code
-- ONLY DEFINE THINGS, DONT EXECUTE THEM


-- Programmatically generate list of all dungeons and raids, to be used in determining what expansion
-- the instance your are currently inside, actually belongs to.

-- Generate table of dungeon and raid instances by expansion
function GenerateInstanceTables()
  local instTable = {}

  instTable.trackedTypes = "party, raid"

  local numTiers = EJ_GetNumTiers()
  local numToScan = 10000
  local raid = false

  for b=1, 2 do

    local instanceType = ""
    if raid then instanceType = "Raids" else instanceType = "Dungeons" end
    instTable[instanceType] = {}

    for t=1, numTiers do
      EJ_SelectTier(t)
      local tierName = EJ_GetTierInfo(t)
      instTable[instanceType][tierName] = {}

      for i=1, numToScan do
        local id, name = EJ_GetInstanceByIndex(i, raid)
        if name then
          instTable[instanceType][tierName][name] = id
        end
      end
    end
    raid = not raid
  end

  -- Generate a chronologically ordered list of expansion names
  tierList = tierList or (function()
    local tt = {}
    for i=1, EJ_GetNumTiers() do
      tt[i] = EJ_GetTierInfo(i)
    end
    return tt
  end)()
  
  return instTable
end


--[[Figure out which expansion our current instance belongs to.

Problem: Remade dungeons, such as Deadmines, belong to more than 1 expansion,
but retain only one name and instanceID. Making a simple list of ID's insufficient.

At the time of writing (Legion), remade Vanilla dungeons are all Heroic variants.
Meaning, if we enter a "vanilla" instance, on Heroic difficulty, it must be a remake.
We can then simply skip scanning Vanilla, the next hit will accurately tell us our real tier.

This can break if something like a TBC instance is remade, for example, so this is a fragile approach.
--]]
function GetCurrentInstanceTier()
  -- Check that the InstanceTable even exists, if not, create it
  InstanceTable = InstanceTable or GenerateInstanceTables()

  -- Bail out if we're not even in an instance!
  if not IsInInstance() then do return "NotAnInstance" end end


  local name, instanceType, difficulty, difficultyName = GetInstanceInfo()

  -- Determine the search key to be used. This should be refactored somehow.
  local searchType = (
  function()
    if instanceType == "party" then
      return "Dungeons"
    elseif instanceType == "raid" then
      return "Raids"
    end
  end
)()

-- First, check if we even track this type of instance, if not, bail out
if not string.find(InstanceTable.trackedTypes, instanceType) then return "UnknownInstanceType" end

-- Second, is it Heroic? If so, skip all of Vanilla. Else, search the entire instance table
local startIndex = (function()
  if difficulty == 2 then
    return 2
  else return 1
  end
end)()


-- Perform the actual search, scanning by instance name, skipping Classic if we're in Heroic
-- Can't scan using instanceID, since the Encounter Journal is not ready during loading screen, and can't return it
for i = startIndex, #tierList do
  subTable = InstanceTable[searchType][tierList[i]]

  for k, v in pairs(subTable) do
    if (name == k) then
      return tierList[i]
    end
  end
end
return "UnknownTier"
end

-- Celebratory print()
-- print("You are in \""..select(1,GetInstanceInfo()).."\ ("..select(4,GetInstanceInfo())..")\", from the \""..GetCurrentInstanceTier().."\" expansion.")
