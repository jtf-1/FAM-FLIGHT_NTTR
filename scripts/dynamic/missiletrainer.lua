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