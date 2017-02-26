-- For hotloading test code
-- ONLY DEFINE THINGS, DONT EXECUTE THEM

local InstanceTable
local tierList
local _, addonTable = ...
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



function addonTable:GetCurrentInstanceTier()
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

-- Celebratory print()
-- print("You are in \""..select(1,GetInstanceInfo()).."\ ("..select(4,GetInstanceInfo())..")\", from the \""..GetCurrentInstanceTier().."\" expansion.")
