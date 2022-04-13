env.info( '*** MISSION FILE BUILD DATE: 2022-04-13T20:57:56.24Z ***') 
env.info( '[JTF-1] *** JTF-1 STATIC MISSION SCRIPT START ***' )

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN INIT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- debug on/off
BASE:TraceOnOff(false) 

JTF1 = {
    missionRestart = "ADMIN9999", -- Message to trigger mission restart via jtf1-hooks
    flagLoadMission = 9999, -- flag for load misison trigger
}
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
--- Default SRS Text-to-Speech
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Send messages through SRS using STTS
-- Script will try to load the file specified with LocalServerConfigFile [name of settings file] 
-- and LocalServerConfigPath [path to file]. This file should define the path to the SRS installation 
-- directory and the port used by the DCS server instance running the mission. 
--
-- If the settings file is not found, the defaults for srs_path and srs_port will be used.
--
-- Message text will be formatted as a SOUNDTEXT object.
-- 
-- Use MISSIONSRS:SendRadio() to transmit on SRS
--
-- msgText        - [required] STRING. Text of message. Can be plain text or a MOOSE SOUNDTEXT obkect
-- msfFreqs       - [optional] STRING. frequency, or table of frequencies (without any spaces). Default freqs AND modulations will be applied if this is not specified.
-- msgModulations - [optional] STRING. modulation, or table of modulations (without any spaces) if multiple freqs passed. Ignored if msgFreqs is not defined. Default modulations will be applied if this is not specified
--


MISSIONSRS = {
  fileName = "ServerLocalSettings.lua",                           -- name of file containing local server settings
  LocalServerConfigPath = nil,                                    -- path to server srs settings. nil if file is in root of server's savedgames profile.
  LocalServerConfigFile = "LocalServerSettings.txt",              -- srs server settings file name
  defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  defaultSrsPort = 5002,                                          -- default SRS port to use if settings file is not available
  defaultText = "No Message Defined!",                            -- default message if text is nil
  defaultFreqs = "243,251,327,377.8,30",                          -- transmit on guard, CTAF, NTTR TWR and NTTR BLACKJACK as default frequencies
  defaultModulations = "AM,AM,AM,AM,FM",                          -- default modulation (count *must* match qty of freqs)
  defaultVol = "1.0",                                             -- default to full volume
  defaultName = "Server",                                         -- default to server as sender
  defaultCoalition = 0,                                           -- default to spectators
  defaultVec3 = nil,                                              -- point from which transmission originates
  defaultSpeed = 2,                                               -- speed at which message should be played
  defaultGender = "female",                                       -- default gender of sender
  defaultCulture = "en-US",                                       -- default culture of sender
  defaultVoice = "",                                              -- default voice to use
}

function MISSIONSRS:LoadSettings()
  local loadFile  = self.LocalServerConfigFile
  if UTILS.CheckFileExists(self.LocalServerConfigPath, self.LocalServerConfigFile) then
    local loadFile, serverSettings = UTILS.LoadFromFile(self.LocalServerConfigPath, self.LocalServerConfigFile)
    BASE:T({"[MISSIONSRS] Load Server Settings",{serverSettings}})
    if not loadFile then
      BASE:E(string.format("[MISSIONSRS] ERROR: Could not load %s", loadFile))
    else
      self.SRS_DIRECTORY = serverSettings[1] or self.defaultSrsPath
      self.SRS_PORT = serverSettings[2] or self.defaultSrsPort
      self:AddRadio()
      BASE:T({"[MISSIONSRS]",{self}})
    end
  else
    BASE:E(string.format("[MISSIONSRS] ERROR: Could not find %s", loadFile))
  end
end

function MISSIONSRS:AddRadio()
  self.Radio = MSRS:New(self.SRS_DIRECTORY, self.defaultFreqs, self.defaultModulations)
  self.Radio:SetPort(self.SRS_PORT)
  self.Radio:SetGender(self.defaultGender)
  self.Radio:SetCulture(self.defaultCulture)
  self.Radio.name = self.defaultName
end

function MISSIONSRS:SendRadio(msgText, msgFreqs, msgModulations)

  BASE:T({"[MISSIONSRS] SendRadio", {msgText}, {msgFreqs}, {msgModulations}})
  if msgFreqs then
    BASE:T("[MISSIONSRS] tx with freqs change.")
    if msgModulations then
      BASE:T("[MISSIONSRS] tx with mods change.")
    end
  end
  if msgText == (nil or "") then 
    msgText = self.defaultText
  end
  local text = msgText
  local tempFreqs = (msgFreqs or self.defaultFreqs)
  local tempModulations = (msgModulations or self.defaultModulations)
  if not msgText.ClassName then
    BASE:T("[MISSIONSRS] msgText NOT SoundText object.")
    text = SOUNDTEXT:New(msgText) -- convert msgText to SOundText object
  end
  self.Radio:SetFrequencies(tempFreqs)
  self.Radio:SetModulations(tempModulations)
  self.Radio:PlaySoundText(text)
  self.Radio:SetFrequencies(self.defaultFreqs) -- reset freqs to default
  self.Radio:SetModulations(self.defaultModulations) -- rest modulation to default

end


MISSIONSRS:LoadSettings()

 
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
-- value (defined in script header). Sending missionRestart text will trigger restarting the
-- current mission via jtf1-hooks.lua.
--

MISSIONTIMER = {
  durationHrs = 11, -- Mission run time in HOURS
  msgSchedule = {60, 30, 10, 5}, -- Schedule for mission restart warning messages. Time in minutes.
  msgWarning = {}, -- schedule container
  missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ), -- Message to trigger mission restart via jtf1-hooks
  restartDelay =  4, -- time in minutes to delay restart if active clients are present.
}

MISSIONTIMER.durationSecs = MISSIONTIMER.durationHrs * 3600 -- Mission run time in seconds

BASE:T({"[MISSIONTIMER]",{MISSIONTIMER}})

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MISSIONTIMER:AddSchedules()
  if self.msgSchedule ~= nil then
    for i, msgTime in ipairs(self.msgSchedule) do
      self.msgWarning[i] = SCHEDULER:New( nil, 
        function()
          BASE:T("[MISSIONTIMER] TIMER WARNING CALLED at " .. tostring(msgTime) .. " minutes remaining.")
          local msg = "99 all players, mission is scheduled to restart in  " .. msgTime .. " minutes!"
          if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
            MISSIONSRS:SendRadio(msg)
          else -- otherwise, send in-game text message
            MESSAGE:New(msg):ToAll()
          end
        end,
      {msgTime}, self.durationSecs - (msgTime * 60))
    end
  end
  self.msgWarning["restart"] = SCHEDULER:New( nil,
    function()
      MISSIONTIMER:Restart()
    end,
    { }, self.durationSecs)
end

function MISSIONTIMER:Restart()
  if not self.clientList then
    self.clientList = SET_CLIENT:New()
    self.clientList:FilterActive()
    self.clientList:FilterStart()
  end
  if self.clientList:CountAlive() > 0 then
    local delayTime = self.restartDelay
    local msg  = "99 all players, mission will restart when no active clients are present. Next check will be in " .. tostring(delayTime) .." minutes." 
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    self.msgWarning["restart"] = SCHEDULER:New( nil,
      function()
        MISSIONTIMER:Restart()
      end,
      { }, (self.restartDelay * 60))
  else
    BASE:T("[MISSIONTIMER] RESTART MISSION")
    MESSAGE:New(self.missionRestart):ToAll()
  end
end

MISSIONTIMER:AddSchedules()

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
 
