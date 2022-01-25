TESTLUA = {}

-- Initialise menu elements
TESTLUA.menuadded = {}
TESTLUA.MenuF10 = {}

-- Add event handler
TESTLUA.eventHandler = EVENTHANDLER:New()
TESTLUA.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
TESTLUA.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

-- check player is present and unit is alive
function TESTLUA:GetPlayerUnitAndName(unitname)

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

  -- Return nil if player not found.
  return nil,nil

end

-- command function
function TESTLUA:testCommand(unitname)

    local unit, playername = TESTLUA:GetPlayerUnitAndName(unitname)
    MESSAGE:New("[TEST MENU] menuTestUnit called by: " .. playername .. "\nIn Unit: " .. unit:GetName()):ToAll()
    BASE:I("[TEST MENU] menuTestUnit called by: " .. playername .. "\nIn Unit: " .. unit:GetName())

end

-- addmenu for unit.
function TESTLUA:AddMenu(unitname)

    local unit, playername = TESTLUA:GetPlayerUnitAndName(unitname)

    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()

    BASE:I("[TEST MENU] AddMenu called for unit: [" .. unitname .. "] and Playername: [" .. playername .. "]")

    if TESTLUA.menuadded[uid] == nil then


        if TESTLUA.MenuF10[gid] == nil then

            BASE:I("[TEST MENU] Adding Submenu for group: " .. group:GetName())
            TESTLUA.MenuF10[gid] = MENU_GROUP:New(group, "[" .. group:GetName() .. "] F10 MENU")

        end

        if TESTLUA.MenuF10[gid][uid] == nil then

            BASE:I("[TEST MENU] Add command for player: " .. playername)
            TESTLUA.MenuF10[gid][uid] = MENU_GROUP_COMMAND:New(group, "[" .. playername .."]["..unitname.."] TEST COMMAND", TESTLUA.MenuF10[gid], TESTLUA.testCommand, self, unitname)

        end
        
        TESTLUA.menuadded[uid] = true

    end


end

-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function TESTLUA.eventHandler:OnEventPlayerEnterAircraft(EventData) -- OnEventBirth or OnEventPlayerEnterAircraft
    
    local unitname = EventData.IniUnitName
    local unit, playername = TESTLUA:GetPlayerUnitAndName(unitname)

    if unit and playername then

        BASE:I("[TEST MENU] Player " .. playername .. " entered unit: " .. unitname .. " UID: " .. unit:GetID())
        SCHEDULER:New(nil, TESTLUA.AddMenu, {TESTLUA, unitname, true},0.1)

    end

end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function TESTLUA.eventHandler:OnEventPlayerLeaveUnit(EventData)

    local playername = EventData.IniPlayerName
    local unit = EventData.IniUnit
    local gid = EventData.IniGroup:GetID()
    local uid = EventData.IniUnit:GetID()
    
    BASE:I("[TEST MENU] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
    
    if gid and uid then

        if TESTLUA.MenuF10[gid] then

            if TESTLUA.MenuF10[gid][uid] then

                BASE:I("[TEST MENU] Removing menu for unit UID:" .. uid)
                TESTLUA.MenuF10[gid][uid]:Remove()
                TESTLUA.MenuF10[gid][uid] = nil
                TESTLUA.menuadded[uid] = nil
            end  

        end
            
    end
                
end

--- END MISSILE TRAINER