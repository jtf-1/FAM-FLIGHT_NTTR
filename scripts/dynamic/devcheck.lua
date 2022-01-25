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