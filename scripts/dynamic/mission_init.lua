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