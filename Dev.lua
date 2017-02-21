-- For hotloading test code
-- ONLY DEFINE THINGS, DONT EXECUTE THEM
local dungInfo = {}

dungInfo[1] = "instanceID"
dungInfo[2] = "name"
dungInfo[3] = "desc"
dungInfo[4] = "bgTex"
dungInfo[5] = "btnTex"
dungInfo[6] = "loreTex"
dungInfo[7] = "moreTex"
dungInfo[8] = "shouldDispDiff"
dungInfo[9] = "link"
dungInfo[10] = "unknownBool" -- Only displays true for Pandaria and Broken Isles!!?

InstanceList = {}

function GenerateInstanceList()
  wipe(InstanceList)

  local numTiers = EJ_GetNumTiers()
  local numToScan = 10000
  local raid = false

  for b=1, 2 do

    local instanceType = ""
    if raid then instanceType = "Raids" else instanceType = "Dungeons" end
    InstanceList[instanceType] = {}

    for t=1, numTiers do
      EJ_SelectTier(t)
      local tierName = EJ_GetTierInfo(t)
      InstanceList[instanceType][tierName] = {}

      for i=1, numToScan do
        local id, name = EJ_GetInstanceByIndex(i, raid)
        if name then
          InstanceList[instanceType][tierName][name] = id
        end
      end
    end
    raid = not raid
  end
end
