-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN SUPPORT AIRCRAFT SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- define table of respawning support aircraft ---
local TableSpawnSupport = { -- {spawnobjectname, spawnzone, callsignName, callsignNumber}
  {
    spawnobject     = "AR230V_KC-130_01", 
    spawnzone       = "AR230V", 
    callsignName    = 2, 
    callsignNumber  = 3
  },
  {
    spawnobject     = "AR641A_KC-135_01", 
    spawnzone       = "AR641A", 
    callsignName    = 1,
    callsignNumber  = 1
  },
  {
    spawnobject     = "AR641A_KC-135MPRS_01", 
    spawnzone       = "AR641A", 
    callsignName    = 3,
    callsignNumber  = 1
  },
  {
    spawnobject     = "AWACS_DARKSTAR", 
    spawnzone       = "AWACS", 
    callsignName    = 5, 
    callsignNumber  = 1
  },
}

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone

  --local SupportSpawn = _args[1]
  local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )
  SupportSpawnObject:InitLimit( 1, 50 )
    :OnSpawnGroup(
      function ( SpawnGroup )
        --SpawnGroup:CommandSetCallsign(SupportSpawn.callsignName, SupportSpawn.callsignNumber)
        local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
        local CheckTanker = SCHEDULER:New( nil, 
        function ()
          if SpawnGroup then
            if SpawnGroup:IsNotInZone( ZONE:FindByName(SupportSpawn.spawnzone) ) then
              SupportSpawnObject:ReSpawn( SpawnIndex )
            end
          end
        end,
        {}, 0, 60 )
      end
    )
    :InitRepeatOnLanding()
    :Spawn()
 
end

-- spawn support aircraft ---
for i, v in ipairs( TableSpawnSupport ) do
  SpawnSupport ( v )
end

--- END SUPPORT AIRCRAFT SECTION