-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Disable AI for ground targets and FAC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local setGroupGroundActive = SET_GROUP:New():FilterActive():FilterCategoryGround():FilterOnce()

-- Prefix for groups for which AI should NOT be disabled
local excludeAI = "BLUFOR"

setGroupGroundActive:ForEachGroup(
  function(activeGroup)
    if not string.find(activeGroup:GetName(), excludeAI) then
      activeGroup:SetAIOff()
    end      
  end
)

---  END DISABLE AI