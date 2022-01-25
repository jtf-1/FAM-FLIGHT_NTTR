env.info( '*** MISSION FILE BUILD DATE: 2022-01-25T22:20:21.15Z ***') 
env.info( '*** JTF-1 STATIC MISSION SCRIPT START ***' )

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN INIT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- debug on/off
BASE:TraceOnOff(false) 

JTF = {}
--- activate admin menu option in admin slots if true
JtfAdmin = true 

-- mission flag for triggering reload/loading of missions
flagLoadMission = 9999

-- value for triggering loading of base mission
flagBaseMissionValue = 1

-- value for triggering loading of dev mission
flagDevMissionValue = 99

--- Name of client unit used for admin control
adminUnitName = "XX_" -- string to locate within unit name for admin slots

--- Dynamic list of all clients
--JTF.SetClient = SET_CLIENT:New():FilterStart()

-- flag value to trigger reloading of DEV mission
devMission = 99

--- END INIT
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Check for Static or Dynamic mission file loading flag
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 then

  env.warning('*** JTF-1 - DEV flag is ON! ***')
  MESSAGE:New("Dev Mode is ON!"):ToAll()

  local DEV_MENU = {
    traceOn = false, -- default tracestate false == trace off, true == trace on.
  }

  function DEV_MENU:restart()
    trigger.action.setUserFlag(flagLoadMission, flagDevMissionValue)
  end

  function DEV_MENU:toggleTrace(traceOn)
    if self.traceOn then
      BASE:TraceOff()
    else
      BASE:TraceOn()
    end
    self.traceOn = not traceOn
  end

  function DEV_MENU:testLua(IncludeFile)
    local base = _G
    local __filepath = 'E:/GitHub/FUN-MAP_NTTR/scripts/dynamic/'
                local f = assert( base.loadfile( __filepath .. IncludeFile ) )
    if f == nil then
      error ("[DEVCHECK] Loader: could not load mission file " .. IncludeFile )
    else
      env.info( "[DEVCHECK] Loader: " .. IncludeFile .. " dynamically loaded." )
                        return f()
    end
  end

  -- Add Dev submenu to F10 Other
  DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
  -- add command to OTHER menu root to retart dev mission
  DEV_MENU.reload = MENU_MISSION_COMMAND:New("Reload DEV Mission.", DEV_MENU.topmenu, DEV_MENU.restart, DEV_MENU)
  DEV_MENU.traceOnOff = MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, DEV_MENU.toggleTrace, DEV_MENU, DEV_MENU.traceOn)
  DEV_MENU.loadTest = MENU_MISSION_COMMAND:New("Load Test LUA.", DEV_MENU.topmenu, DEV_MENU.testLua, "test.lua")

  -- trace all events
  BASE:TraceAll(true)
else
  env.info('*** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ADMIN MENU SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
ADMIN = EVENTHANDLER:New()
ADMIN:HandleEvent(EVENTS.PlayerEnterAircraft)

function ADMIN:GetPlayerUnitAndName(unitName)
  if unitName ~= nil then
    -- Get DCS unit from its name.
    local DCSunit = Unit.getByName(unitName)
    if DCSunit then
      local playername=DCSunit:getPlayerName()
      local unit = UNIT:Find(DCSunit)
      if DCSunit and unit and playername then
        return unit, playername
      end
    end
  end
  -- Return nil if we could not find a player.
  return nil,nil
end

function ADMIN:OnEventPlayerEnterAircraft(EventData)
  local unitName = EventData.IniUnitName
  local unit, playername = ADMIN:GetPlayerUnitAndName(unitName)
  if unit and playername then
      SCHEDULER:New(nil, ADMIN.BuildAdminMenu, {self, unit, playername}, 0.5)
  end
end

--- Set mission flag to load a new mission.
--- 1 = NTTR Day.
--- 2 = NTTR Day IFR.
--- 3 = NTTR Night.
--- 4 = NTTR Night No Moon.
-- @param #string playerName Name of client calling restart command.
-- @param #number mapFlagValue Mission number to which flag should be set.
function ADMIN:LoadMission(playerName, mapFlagValue)
  if playerName then
    env.info("ADMIN Restart player name: " .. playerName)
  end
  trigger.action.setUserFlag(flagLoadMission, mapFlagValue) 
end

--- Add admin menu and commands if client is in an ADMIN spawn
-- @param #object unit Unit of player.
-- @param #string playername Name of player
function ADMIN:BuildAdminMenu(unit,playername)
  local adminGroup = unit:GetGroup()
  local adminGroupName = adminGroup:GetName()
  local adminMenu = MENU_GROUP:New(adminGroup, "Admin")
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR", adminMenu, ADMIN.LoadMission, self, playername, 1 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR - IFR", adminMenu, ADMIN.LoadMission, self, playername, 2 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR", adminMenu, ADMIN.LoadMission, self, playername, 3 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - No Moon", adminMenu, ADMIN.LoadMission, self, playername, 4 )
end

--- END ADMIN MENU SECTION
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSION TIMER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Mission Timer
--
-- Add schedules to display messages at set intervals prior to restarting the base mission.
-- ME switched triggers should be set to a FLAG EQUALS condition for the flag flagLoadMission
-- value (defined in script header). The flag value 1 should trigger a LOAD MISSION for the
-- base (default) map.
--
--

local MissionTimer = {}

-- Mission run time in HOURS
MissionTimer.durationHrs = 2

-- Schedule for mission restart warning messages. Time in minutes.
MissionTimer.msgSchedule = {60, 30, 10, 5}

-- Mission run time in seconds
MissionTimer.durationSecs = MissionTimer.durationHrs * 3600

-- schedule container
MissionTimer.msgWarning = {}

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MissionTimer:AddSchedules()

  for i, msgTime in ipairs(self.msgSchedule) do

    self.msgWarning[i] = SCHEDULER:New( nil, 
      function()
        MESSAGE:New("Mission will restart in " .. msgTime .. " minutes!"):ToAll()
      end,
    {msgTime}, self.durationSecs - (msgTime * 60))

  end

  self.msgWarning["restart"] = SCHEDULER:New( nil,
    function()
      MESSAGE:New("Mission is restarting now!"):ToAll()
      trigger.action.setUserFlag(flagLoadMission, flagBaseMissionValue)
    end,
    { }, self.durationSecs)

end

MissionTimer:AddSchedules()

--- END MISSION TIMER
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSILE TRAINER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MTRAINER = {
  menuadded = {},
  MenuF10   = {},
  safeZone = nil, -- safezone to use, otherwise nil --"ZONE_FOX"
  launchZone = nil, -- launchzone to use, otherwise nil --"ZONE_FOX"
  DefaultLaunchAlerts = false,
  DefaultMissileDestruction = false,
  DefaultLaunchMarks = false,
  ExplosionDistance = 300,
}
-- Create MTRAINER container and defaults

-- add event handler
MTRAINER.eventHandler = EVENTHANDLER:New()
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

-- check player is present and unit is alive
function MTRAINER:GetPlayerUnitAndName(unitname)
  if unitname ~= nil then
    local DCSunit = Unit.getByName(unitname)
    if DCSunit then
      local playername=DCSunit:getPlayerName()
      local unit = UNIT:Find(DCSunit)
      if DCSunit and unit and playername then
        return unit, playername
      end
    end
  end
  -- Return nil if we could not find a player.
  return nil,nil
end

-- add new FOX class to the Missile Trainer
MTRAINER.fox = FOX:New()

--- FOX Default Settings
MTRAINER.fox:SetDefaultLaunchAlerts(MTRAINER.DefaultLaunchAlerts)
MTRAINER.fox:SetDefaultMissileDestruction(MTRAINER.DefaultMissileDestruction)
MTRAINER.fox:SetDefaultLaunchMarks(MTRAINER.DefaultLaunchMarks)
MTRAINER.fox:SetExplosionDistance(MTRAINER.ExplosionDistance)
MTRAINER.fox:SetDebugOnOff()
MTRAINER.fox:SetDisableF10Menu()

-- zone in which players will be protected
if MTRAINER.safeZone then
  MTRAINER.fox:AddSafeZone(ZONE:New(MTRAINER.safeZone))
end

-- zone in which launches will be tracked
if MTRAINER.launchZone then
  MTRAINER.fox:AddLaunchZone(ZONE:New(MTRAINER.launchZone))
end

-- start the missile trainer
MTRAINER.fox:Start()

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #string unitname name of client unit
function MTRAINER:ToggleTrainer(unitname)
  self.fox:_ToggleLaunchAlert(unitname)
  self.fox:_ToggleDestroyMissiles(unitname)
end

--- Add Missile Trainer for GROUP|UNIT in F10 root menu.
-- @param #string unitname Name of unit occupied by client
function MTRAINER:AddMenu(unitname)
  local unit, playername = self:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if MTRAINER.menuadded[uid] == nil then
        -- add GROUP menu if not already present
        if MTRAINER.MenuF10[gid] == nil then
          BASE:T("[MTRAINER] Adding menu for group: " .. group:GetName())
          MTRAINER.MenuF10[gid] = MENU_GROUP:New(group, "Missile Trainer")
        end
        if MTRAINER.MenuF10[gid][uid] == nil then
          BASE:T("[MTRAINER] Add submenu for player: " .. playername)
          MTRAINER.MenuF10[gid][uid] = MENU_GROUP:New(group, playername, MTRAINER.MenuF10[gid])
          BASE:T("[MTRAINER] Add commands for player: " .. playername)
          MENU_GROUP_COMMAND:New(group, "Missile Trainer On/Off", MTRAINER.MenuF10[gid][uid], MTRAINER.ToggleTrainer, MTRAINER, unitname)
          MENU_GROUP_COMMAND:New(group, "My Status", MTRAINER.MenuF10[gid][uid], MTRAINER.fox._MyStatus, MTRAINER.fox, unitname)
        end
        MTRAINER.menuadded[uid] = true
      end
    else
      BASE:T(string.format("[MTRAINER] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    BASE:T(string.format("[MTRAINER] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end

-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerEnterAircraft(EventData) 
  local unitname = EventData.IniUnitName
  local unit, playername = MTRAINER:GetPlayerUnitAndName(unitname)
  if unit and playername then
    SCHEDULER:New(nil, MTRAINER.AddMenu, {MTRAINER, unitname, true},0.1)
  end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerLeaveUnit(EventData)
  local playername = EventData.IniPlayerName
  local unit = EventData.IniUnit
  local gid = EventData.IniGroup:GetID()
  local uid = EventData.IniUnit:GetID()
  BASE:T("[MTRAINER] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
  if gid and uid then
    if MTRAINER.MenuF10[gid] then
      BASE:T("[MTRAINER] Removing menu for unit UID:" .. uid)
      MTRAINER.MenuF10[gid][uid]:Remove()
      MTRAINER.MenuF10[gid][uid] = nil
      MTRAINER.menuadded[uid] = nil
    end
  end
end

--- END MISSILE TRAINER
 
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
 
env.info( '*** JTF-1 MOOSE MISSION SCRIPT END ***' )
 
